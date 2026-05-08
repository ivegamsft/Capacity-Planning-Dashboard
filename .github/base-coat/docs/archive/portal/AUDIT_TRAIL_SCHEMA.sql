-- Basecoat Portal Audit Trail & Compliance Logging Schema
-- Version: 1.0
-- Purpose: Comprehensive audit trail for all identity and authorization events

-- ============================================================================
-- AUDIT EVENTS TABLE - Core audit logging
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    actor_id UUID,  -- NULL for system-generated events
    actor_email VARCHAR(255),
    subject_id UUID,  -- User/resource affected by action
    subject_email VARCHAR(255),
    action_detail JSONB,  -- Event-specific structured data
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON DELETE CASCADE
);

CREATE INDEX idx_audit_org_timestamp 
    ON audit_events(org_id, created_at DESC);
CREATE INDEX idx_audit_event_type 
    ON audit_events(event_type);
CREATE INDEX idx_audit_actor_id 
    ON audit_events(actor_id);
CREATE INDEX idx_audit_subject_id 
    ON audit_events(subject_id);

-- ============================================================================
-- AUTHENTICATION EVENTS
-- ============================================================================

-- User login events
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, actor_email,
    action_detail, ip_address, user_agent, created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'user_login',
    'user-uuid-here',
    'user@company.com',
    jsonb_build_object(
        'method', 'github_oauth',
        'success', true,
        'session_id', 'session-uuid-here',
        'mfa_verified', true
    ),
    '192.168.1.1'::inet,
    'Mozilla/5.0...',
    NOW()
);

-- Failed login attempt
INSERT INTO audit_events (
    event_id, org_id, event_type, action_detail,
    ip_address, user_agent, created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'login_failed',
    jsonb_build_object(
        'email', 'attacker@external.com',
        'reason', 'invalid_credentials',
        'attempt_count', 3
    ),
    '203.0.113.42'::inet,
    'Mozilla/5.0...',
    NOW()
);

-- User logout
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'user_logout',
    'user-uuid-here',
    jsonb_build_object(
        'session_duration_seconds', 3600,
        'graceful', true
    ),
    NOW()
);

-- ============================================================================
-- AUTHORIZATION & PERMISSION EVENTS
-- ============================================================================

-- Permission granted
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, actor_email,
    subject_id, subject_email, action_detail, created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'permission_granted',
    'admin-uuid-here',
    'admin@company.com',
    'user-uuid-here',
    'user@company.com',
    jsonb_build_object(
        'permission', 'read:audits',
        'reason', 'Promoted to auditor role',
        'scope', 'organization',
        'effective_date', NOW()
    ),
    NOW()
);

-- Permission denied attempt
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    ip_address, created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'permission_denied',
    'user-uuid-here',
    jsonb_build_object(
        'endpoint', 'POST /api/users',
        'required_permission', 'manage:users',
        'reason', 'User lacks required permission'
    ),
    '192.168.1.1'::inet,
    NOW()
);

-- ============================================================================
-- ROLE ASSIGNMENT EVENTS
-- ============================================================================

-- Role assigned
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, actor_email,
    subject_id, subject_email, action_detail, created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'role_assigned',
    'org-admin-uuid-here',
    'orgadmin@company.com',
    'user-uuid-here',
    'user@company.com',
    jsonb_build_object(
        'role', 'auditor',
        'previous_roles', ARRAY['developer'],
        'team_ids', ARRAY['team-1', 'team-2'],
        'reason', 'Team lead promotion'
    ),
    NOW()
);

-- Role removed
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    subject_id, created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'role_removed',
    'admin-uuid-here',
    jsonb_build_object(
        'role', 'admin',
        'reason', 'User departure',
        'effective_date', NOW()
    ),
    'user-uuid-here',
    NOW()
);

-- ============================================================================
-- API KEY EVENTS
-- ============================================================================

-- API key generated
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'api_key_generated',
    'user-uuid-here',
    jsonb_build_object(
        'key_id', 'key-uuid-here',
        'key_prefix', 'bcp_org_12345_4x7q9w',
        'scopes', ARRAY['read:audits', 'write:audits'],
        'expires_at', (NOW() + INTERVAL '90 days'),
        'description', 'GitHub Actions CI/CD'
    ),
    NOW()
);

-- API key used
INSERT INTO audit_events (
    event_id, org_id, event_type, action_detail,
    ip_address, created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'api_key_used',
    jsonb_build_object(
        'key_id', 'key-uuid-here',
        'endpoint', 'POST /api/audits',
        'success', true,
        'response_time_ms', 245
    ),
    '203.0.113.99'::inet,
    NOW()
);

-- API key revoked
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'api_key_revoked',
    'user-uuid-here',
    jsonb_build_object(
        'key_id', 'key-uuid-here',
        'reason', 'Credentials compromised',
        'days_until_expiry', 45
    ),
    NOW()
);

-- ============================================================================
-- MFA EVENTS
-- ============================================================================

-- MFA enabled
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'mfa_enabled',
    'user-uuid-here',
    jsonb_build_object(
        'method', 'totp',
        'device_name', 'Google Authenticator',
        'backup_codes_generated', 10
    ),
    NOW()
);

-- MFA verification failed
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    ip_address, created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'mfa_verification_failed',
    'user-uuid-here',
    jsonb_build_object(
        'method', 'totp',
        'attempt', 2,
        'max_attempts', 3,
        'reason', 'Incorrect code'
    ),
    '192.168.1.1'::inet,
    NOW()
);

-- ============================================================================
-- SESSION EVENTS
-- ============================================================================

-- Session created
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'session_created',
    'user-uuid-here',
    jsonb_build_object(
        'session_id', 'session-uuid-here',
        'expires_at', (NOW() + INTERVAL '8 hours'),
        'concurrent_sessions', 2
    ),
    NOW()
);

-- Session timeout
INSERT INTO audit_events (
    event_id, org_id, event_type, actor_id, action_detail,
    created_at
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'session_timeout',
    'user-uuid-here',
    jsonb_build_object(
        'session_id', 'session-uuid-here',
        'reason', 'inactivity',
        'idle_minutes', 30
    ),
    NOW()
);

-- ============================================================================
-- PERMISSION AUDIT TABLE - Track permission changes over time
-- ============================================================================

CREATE TABLE IF NOT EXISTS permission_audit (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL,
    user_id UUID NOT NULL,
    permission_code VARCHAR(100) NOT NULL,
    granted_by UUID,
    granted_at TIMESTAMP NOT NULL,
    revoked_by UUID,
    revoked_at TIMESTAMP,
    reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (org_id) REFERENCES organizations(org_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (granted_by) REFERENCES users(user_id),
    FOREIGN KEY (revoked_by) REFERENCES users(user_id)
);

CREATE INDEX idx_permission_audit_user 
    ON permission_audit(org_id, user_id);
CREATE INDEX idx_permission_audit_permission 
    ON permission_audit(permission_code);
CREATE INDEX idx_permission_audit_date 
    ON permission_audit(granted_at DESC);

-- Example: Track when user_X gets read:audits permission
INSERT INTO permission_audit (
    permission_id, org_id, user_id, permission_code,
    granted_by, granted_at, reason
) VALUES (
    gen_random_uuid(),
    'org-uuid-here',
    'user-uuid-here',
    'read:audits',
    'admin-uuid-here',
    NOW(),
    'Promoted to auditor role'
);

-- ============================================================================
-- COMPLIANCE REPORTING VIEWS
-- ============================================================================

-- View: All user actions in the past 24 hours
CREATE OR REPLACE VIEW v_recent_user_actions AS
SELECT
    event_id,
    org_id,
    event_type,
    actor_id,
    actor_email,
    action_detail,
    ip_address,
    created_at
FROM audit_events
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- View: Failed authentication attempts
CREATE OR REPLACE VIEW v_failed_auth_attempts AS
SELECT
    event_id,
    org_id,
    action_detail->>'email' AS attempted_email,
    action_detail->>'reason' AS failure_reason,
    ip_address,
    created_at
FROM audit_events
WHERE event_type = 'login_failed'
  AND created_at >= NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;

-- View: Admin actions (high-risk)
CREATE OR REPLACE VIEW v_admin_actions AS
SELECT
    event_id,
    org_id,
    event_type,
    actor_id,
    actor_email,
    subject_id,
    action_detail,
    created_at
FROM audit_events
WHERE event_type IN (
    'role_assigned',
    'role_removed',
    'permission_granted',
    'permission_denied',
    'user_created',
    'user_deleted'
)
ORDER BY created_at DESC;

-- ============================================================================
-- RETENTION & CLEANUP POLICIES
-- ============================================================================

-- Delete audit events older than 90 days (change as needed)
-- Run monthly via cron job:
-- DELETE FROM audit_events
-- WHERE created_at < NOW() - INTERVAL '90 days'
--   AND event_type NOT IN ('role_assigned', 'role_removed', 'permission_granted')

-- Compliance events retained for 2 years
-- Run annually:
-- DELETE FROM permission_audit
-- WHERE revoked_at < NOW() - INTERVAL '2 years'

