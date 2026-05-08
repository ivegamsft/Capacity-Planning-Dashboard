---
name: identity-migration
title: Identity Migration to ASP.NET Core & Entra ID
description: Migrate legacy authentication to ASP.NET Core Identity with Entra ID integration, claims-based authentication, and role/password management
compatibility: ["agent:backend-dev"]
metadata:
  domain: identity
  maturity: production
  audience: [backend-engineer, devops-engineer, architect]
allowed-tools: [bash, powershell, docker]
---

# Identity Migration Skill

This skill provides comprehensive guidance for migrating legacy authentication systems to modern ASP.NET Core Identity with Azure Entra ID (Azure AD) integration. It covers ASP.NET Membership to Identity conversion, claims-based authorization, role mapping, password hash compatibility, and OAuth2/OIDC setup.

## Overview

Modern identity management in Azure requires moving from legacy ASP.NET Membership to ASP.NET Core Identity with Entra ID integration. This migration ensures:

- Secure, standards-compliant authentication
- Seamless Azure Entra ID integration
- Claims-based authorization model
- Improved password handling and security
- Single Sign-On (SSO) capabilities
- Multi-factor authentication support

## ASP.NET Membership to ASP.NET Core Identity Migration

### User Model Migration

ASP.NET Membership stores user data in predefined tables. ASP.NET Core Identity uses customizable user classes. Perform the following migration:

```csharp
// Legacy ASP.NET Membership User
public class MembershipUser
{
    public Guid UserId { get; set; }
    public string UserName { get; set; }
    public string Email { get; set; }
    public string PasswordHash { get; set; }
    public DateTime CreateDate { get; set; }
    public bool IsApproved { get; set; }
}

// ASP.NET Core Identity User
public class ApplicationUser : IdentityUser
{
    public DateTime CreateDate { get; set; }
    public bool IsApproved { get; set; }
}
```

### Database Migration Steps

1. Back up the legacy Membership database
2. Create new ASP.NET Core Identity schema using Entity Framework Core migrations
3. Write migration script to copy user data to new tables
4. Handle password hash algorithm conversion
5. Migrate roles and user-role relationships
6. Update connection strings and configuration

```sql
-- Example: Migrate user data from legacy tables
INSERT INTO AspNetUsers (Id, UserName, Email, PasswordHash, CreatedDate, IsApproved)
SELECT 
    CONVERT(NVARCHAR(MAX), UserId),
    UserName,
    Email,
    PasswordHash,  -- Will require hash conversion
    CreateDate,
    IsApproved
FROM aspnet_Users
WHERE UserName IS NOT NULL;
```

### Password Hash Compatibility

ASP.NET Membership uses PBKDF2 hashing. ASP.NET Core Identity can verify legacy hashes during login. Implement a custom password hasher for seamless transition:

```csharp
public class LegacyPasswordHasher : PasswordHasher<ApplicationUser>
{
    private readonly MembershipPasswordHasher _legacyHasher;

    public LegacyPasswordHasher()
    {
        _legacyHasher = new MembershipPasswordHasher();
    }

    public override PasswordVerificationResult VerifyHashedPassword(
        ApplicationUser user, string hash, string providedPassword)
    {
        // First try new identity hash
        var result = base.VerifyHashedPassword(user, hash, providedPassword);
        if (result == PasswordVerificationResult.Success)
            return result;

        // Fall back to legacy hash verification
        if (_legacyHasher.VerifyPassword(hash, providedPassword))
        {
            // Hash using new algorithm and update database
            user.PasswordHash = HashPassword(user, providedPassword);
            return PasswordVerificationResult.SuccessRehashNeeded;
        }

        return PasswordVerificationResult.Failed;
    }
}
```

## Claims-Based Authentication

Modern authentication uses claims instead of roles. Claims represent facts about the user (identity, permissions, attributes).

### Converting Roles to Claims

```csharp
public class ClaimsTransformation : IClaimsTransformation
{
    private readonly UserManager<ApplicationUser> _userManager;

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        if (!principal.FindFirst(ClaimTypes.NameIdentifier)?.Value != null)
        {
            var user = await _userManager.FindByNameAsync(
                principal.FindFirst(ClaimTypes.Name)?.Value);

            if (user != null)
            {
                var identity = principal.Identity as ClaimsIdentity;
                var roles = await _userManager.GetRolesAsync(user);

                foreach (var role in roles)
                {
                    identity?.AddClaim(new Claim(ClaimTypes.Role, role));
                }
            }
        }

        return principal;
    }
}
```

### Adding Custom Claims

```csharp
public async Task AddCustomClaimsAsync(ApplicationUser user, ClaimsIdentity identity)
{
    identity.AddClaim(new Claim("department", user.Department));
    identity.AddClaim(new Claim("costcenter", user.CostCenter));
    identity.AddClaim(new Claim("manager", user.ManagerId));
    
    var roles = await _userManager.GetRolesAsync(user);
    foreach (var role in roles)
    {
        identity.AddClaim(new Claim(ClaimTypes.Role, role));
    }
}
```

## Role Migration

### Mapping Legacy Roles to Identity Roles

```csharp
public class RoleMigrationService
{
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly UserManager<ApplicationUser> _userManager;

    public async Task MigrateRolesAsync(IEnumerable<LegacyRole> legacyRoles)
    {
        foreach (var legacyRole in legacyRoles)
        {
            var role = new IdentityRole 
            { 
                Name = legacyRole.RoleName,
                NormalizedName = legacyRole.RoleName.ToUpper()
            };

            var result = await _roleManager.CreateAsync(role);
            if (result.Succeeded)
            {
                // Add role claims for granular permissions
                var permissionClaim = new Claim("permission", legacyRole.RoleName);
                await _roleManager.AddClaimAsync(role, permissionClaim);
            }
        }
    }

    public async Task MigrateUserRolesAsync(
        ApplicationUser user, 
        IEnumerable<string> legacyRoles)
    {
        var validRoles = (await _roleManager.Roles.ToListAsync())
            .Where(r => legacyRoles.Contains(r.Name))
            .Select(r => r.Name);

        foreach (var role in validRoles)
        {
            await _userManager.AddToRoleAsync(user, role);
        }
    }
}
```

## Entra ID (Azure AD) Integration

### Configuring OpenID Connect

Add Azure Entra ID authentication to your ASP.NET Core application:

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
        .AddMicrosoftIdentityWebApp(Configuration.GetSection("AzureAd"));

    services.AddAuthorization(options =>
    {
        options.AddPolicy("AdminOnly", policy =>
            policy.RequireRole("admin"));
    });
}

public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    app.UseAuthentication();
    app.UseAuthorization();
    
    app.UseRouting();
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapControllers();
    });
}
```

### Azure AD Configuration

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "common",
    "ClientId": "your-app-id-here",
    "Audience": "api://your-api-app-id",
    "CallbackPath": "/signin-oidc"
  }
}
```

### Hybrid Scenario: Local + Entra ID

Support both legacy local accounts and Entra ID accounts:

```csharp
public class HybridAuthenticationOptions
{
    public const string LocalScheme = "LocalIdentity";
    public const string EntraIdScheme = OpenIdConnectDefaults.AuthenticationScheme;
}

public void ConfigureServices(IServiceCollection services)
{
    services.AddAuthentication(options =>
    {
        options.DefaultScheme = "MultiScheme";
        options.DefaultChallengeScheme = HybridAuthenticationOptions.EntraIdScheme;
    })
    .AddCookie(HybridAuthenticationOptions.LocalScheme)
    .AddMicrosoftIdentityWebApp(
        Configuration.GetSection("AzureAd"),
        cookieScheme: "MicrosoftCookie");
}
```

## Password Hash Conversion

### PBKDF2 to Argon2 Migration

ASP.NET Membership uses PBKDF2. Modern ASP.NET Core Identity supports stronger algorithms. Implement gradual migration:

```csharp
public class PasswordMigrationService
{
    private readonly UserManager<ApplicationUser> _userManager;

    public async Task<PasswordVerificationResult> VerifyAndUpgradeAsync(
        ApplicationUser user, 
        string password,
        string legacyHash)
    {
        // Check legacy hash
        if (VerifyLegacyHash(legacyHash, password))
        {
            // Upgrade password to new hash on successful login
            user.PasswordHash = _userManager.PasswordHasher.HashPassword(user, password);
            await _userManager.UpdateAsync(user);
            return PasswordVerificationResult.SuccessRehashNeeded;
        }

        return PasswordVerificationResult.Failed;
    }

    private bool VerifyLegacyHash(string hash, string password)
    {
        // Implementation of PBKDF2 verification
        using (var pbkdf2 = new Rfc2898DeriveBytes(
            password, 
            Encoding.UTF8.GetBytes(hash.Substring(0, 16)),
            iterations: 1000))
        {
            string hashOfInput = Convert.ToBase64String(pbkdf2.GetBytes(20));
            return hash.EndsWith(hashOfInput);
        }
    }
}
```

## OAuth2/OIDC Setup

### Adding OAuth2 Providers

Configure multiple OAuth2 providers for flexibility:

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddAuthentication()
        .AddMicrosoftAccount(options =>
        {
            options.ClientId = Configuration["Authentication:Microsoft:ClientId"];
            // Never store secrets in config files — use Azure Key Vault, environment variables, or managed identity
            options.ClientSecret = Configuration["Authentication:Microsoft:ClientSecret"]; // load from Key Vault or env var
        })
        .AddGoogle(options =>
        {
            options.ClientId = Configuration["Authentication:Google:ClientId"];
            // Never store secrets in config files — use Azure Key Vault, environment variables, or managed identity
            options.ClientSecret = Configuration["Authentication:Google:ClientSecret"]; // load from Key Vault or env var
        });
}
```

### OIDC Token Handling

```csharp
public class OidcTokenHandler
{
    public async Task<string> RefreshTokenAsync(string refreshToken)
    {
        var tokenClient = new HttpClient();
        var discoveryDocument = await GetDiscoveryDocumentAsync();

        var refreshRequest = new RefreshTokenRequest
        {
            Address = discoveryDocument.TokenEndpoint,
            ClientId = "your-app-id",
            // WARNING: Prefer certificate credentials or managed identity over client secrets.
            // If a secret is required, load it from Key Vault or environment variable — never hardcode.
            ClientSecret = Environment.GetEnvironmentVariable("OIDC_CLIENT_SECRET"),
            RefreshToken = refreshToken
        };

        var response = await tokenClient.RequestRefreshTokenAsync(refreshRequest);
        return response.AccessToken;
    }
}
```

## Migration Checklist

- [ ] Back up legacy Membership database
- [ ] Create ASP.NET Core Identity database schema
- [ ] Implement custom password hasher for legacy hash compatibility
- [ ] Migrate user accounts and validate data integrity
- [ ] Migrate roles and permissions
- [ ] Implement claims-based authorization policies
- [ ] Configure Entra ID (Azure AD) integration
- [ ] Set up hybrid authentication (local + Entra ID)
- [ ] Configure OAuth2/OIDC providers
- [ ] Test login flows for all authentication methods
- [ ] Implement password reset and MFA
- [ ] Monitor legacy authentication deprecation
- [ ] Plan user communication for authentication changes

## References

- Microsoft Identity Platform Documentation
- ASP.NET Core Identity Documentation
- Azure Entra ID Integration Guide
- OAuth 2.0 and OpenID Connect Specifications
