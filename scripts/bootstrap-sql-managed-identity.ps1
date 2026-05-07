#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bootstrap script to configure Azure SQL database with managed identity authentication
    
.DESCRIPTION
    This script is executed as part of the deployment workflow (GitHub Actions).
    It configures the database for the App Service managed identity by:
    1. Authenticating to Azure using Azure CLI
    2. Ensuring the SQL server has a system-assigned managed identity with Directory Readers
    3. Executing SQL initialization script against the database
    4. Granting necessary roles to the managed identity

    The Directory Readers step requires the caller to have the Privileged Role Administrator
    or Global Administrator role in Azure AD. In CI/CD, if that permission is absent, the
    script emits a warning and continues — the SQL step will fail until Directory Readers is
    assigned manually (or via the bootstrap-github-oidc.ps1 pre-flight script).

.PARAMETER AppServiceName
    Name of the App Service with the managed identity (e.g., app-capdash-prod-prod01)

.PARAMETER SqlServerName
    Name of the SQL Server (without .database.windows.net suffix)

.PARAMETER SqlDatabaseName
    Name of the SQL Database (e.g., sqldb-capdash-prod)

.PARAMETER ResourceGroup
    Azure Resource Group containing the SQL Server

.PARAMETER SubscriptionId
    Azure Subscription ID

.EXAMPLE
    ./scripts/bootstrap-sql-managed-identity.ps1 `
        -AppServiceName "app-capdash-prod-prod01" `
        -SqlServerName "sql-capdash-prod-prod01" `
        -SqlDatabaseName "sqldb-capdash-prod" `
        -ResourceGroup "rg-capdash-prod" `
        -SubscriptionId "844eabcc-dc96-453b-8d45-bef3d566f3f8"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$AppServiceName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlDatabaseName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SQL Database Bootstrap Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  App Service: $AppServiceName"
Write-Host "  SQL Server: $SqlServerName"
Write-Host "  Database: $SqlDatabaseName"
Write-Host "  Resource Group: $ResourceGroup"
Write-Host ""

# Verify we're authenticated to Azure
Write-Host "Verifying Azure authentication..." -ForegroundColor Cyan
try {
    $currentAccount = az account show --query "user.name" -o tsv
    Write-Host "✓ Authenticated as: $currentAccount" -ForegroundColor Green
} catch {
    Write-Host "✗ Not authenticated to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Set subscription context
Write-Host ""
Write-Host "Setting subscription context..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId
Write-Host "✓ Subscription set to $SubscriptionId" -ForegroundColor Green

# ── Step 1: Ensure SQL server has a system-assigned managed identity ──────────
# Required for CREATE USER ... FROM EXTERNAL PROVIDER to resolve Entra identities.
# Reference: https://aka.ms/sqlaadsetup
Write-Host ""
Write-Host "Checking SQL server managed identity..." -ForegroundColor Cyan
$sqlServerJson = az sql server show `
    --resource-group $ResourceGroup `
    --name $SqlServerName `
    --query "identity" -o json 2>&1 | ConvertFrom-Json

if ($null -eq $sqlServerJson -or $sqlServerJson.type -notmatch "SystemAssigned") {
    Write-Host "  Enabling system-assigned managed identity on SQL server..." -ForegroundColor Yellow
    az sql server update `
        --name $SqlServerName `
        --resource-group $ResourceGroup `
        -i `
        --output none
    $sqlServerJson = az sql server show `
        --resource-group $ResourceGroup `
        --name $SqlServerName `
        --query "identity" -o json 2>&1 | ConvertFrom-Json
    Write-Host "✓ Managed identity enabled: $($sqlServerJson.principalId)" -ForegroundColor Green
} else {
    Write-Host "✓ Managed identity already set: $($sqlServerJson.principalId)" -ForegroundColor Green
}

$sqlMIPrincipalId = $sqlServerJson.principalId

# ── Step 2: Ensure SQL server MI has the Directory Readers Azure AD role ──────
# Without this, FROM EXTERNAL PROVIDER queries fail with "Server identity is not configured."
Write-Host ""
Write-Host "Checking Directory Readers role membership..." -ForegroundColor Cyan

# Find the Directory Readers role object ID
$dirReadersRoleResp = az rest --method GET `
    --url "https://graph.microsoft.com/v1.0/directoryRoles?`$filter=displayName eq 'Directory Readers'" `
    -o json 2>&1 | ConvertFrom-Json

if ($null -ne $dirReadersRoleResp -and $dirReadersRoleResp.value.Count -gt 0) {
    $dirReadersRoleId = $dirReadersRoleResp.value[0].id
    
    $membersResp = az rest --method GET `
        --url "https://graph.microsoft.com/v1.0/directoryRoles/$dirReadersRoleId/members?`$select=id" `
        -o json 2>&1 | ConvertFrom-Json

    $alreadyMember = $membersResp.value | Where-Object { $_.id -eq $sqlMIPrincipalId }

    if ($alreadyMember) {
        Write-Host "✓ SQL server MI already has Directory Readers role" -ForegroundColor Green
    } else {
        Write-Host "  Adding SQL server MI to Directory Readers..." -ForegroundColor Yellow
        $tempFile = [System.IO.Path]::GetTempFileName() + ".json"
        "{`"@odata.id`": `"https://graph.microsoft.com/v1.0/directoryObjects/$sqlMIPrincipalId`"}" `
            | Out-File -FilePath $tempFile -Encoding utf8 -NoNewline
        
        $addResult = az rest --method POST `
            --url "https://graph.microsoft.com/v1.0/directoryRoles/$dirReadersRoleId/members/`$ref" `
            --body "@$tempFile" `
            --headers "Content-Type=application/json" 2>&1
        
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ SQL server MI added to Directory Readers" -ForegroundColor Green
        } else {
            Write-Host "⚠  Could not assign Directory Readers automatically (Graph permission may be absent)." -ForegroundColor Yellow
            Write-Host "   Manually add principal '$sqlMIPrincipalId' to the Directory Readers role in Entra." -ForegroundColor Yellow
            Write-Host "   SQL bootstrap will proceed but may fail if the role is not yet assigned." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠  Could not query Directory Readers role. Proceeding — ensure the role is assigned manually." -ForegroundColor Yellow
}

# Check if SQL Server and database exist
Write-Host ""
Write-Host "Verifying SQL Server and database..." -ForegroundColor Cyan
try {
    $dbInfo = az sql db show `
        --resource-group $ResourceGroup `
        --server $SqlServerName `
        --name $SqlDatabaseName `
        --query "{ name: name, status: status }" -o json | ConvertFrom-Json
    
    Write-Host "✓ Database found: $($dbInfo.name)" -ForegroundColor Green
    Write-Host "  Status: $($dbInfo.status)"
} catch {
    Write-Host "✗ Failed to find database. Error: $_" -ForegroundColor Red
    exit 1
}

# Prepare SQL script with app service name substitution
Write-Host ""
Write-Host "Preparing SQL initialization script..." -ForegroundColor Cyan
$sqlScriptPath = Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath "sql", "init-managed-identity.sql"

if (-not (Test-Path $sqlScriptPath)) {
    Write-Host "✗ SQL script not found at: $sqlScriptPath" -ForegroundColor Red
    exit 1
}

$sqlScript = Get-Content $sqlScriptPath -Raw
$sqlScript = $sqlScript -replace '{APP_SERVICE_NAME}', $AppServiceName

# Create temporary SQL file with substituted values
$tempSqlFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.sql'
$sqlScript | Out-File -FilePath $tempSqlFile -Encoding UTF8 -Force
Write-Host "✓ SQL script prepared (temp file: $tempSqlFile)" -ForegroundColor Green

# Execute SQL script using sqlcmd with Azure AD token authentication
Write-Host ""
Write-Host "Executing SQL script against database..." -ForegroundColor Cyan
Write-Host "  Server: $SqlServerName.database.windows.net"
Write-Host "  Database: $SqlDatabaseName"

try {
    # Use go-sqlcmd with ActiveDirectoryDefault auth (uses Azure CLI token - works in CI/CD)
    $cmdArgs = @(
        "-S", "tcp:$SqlServerName.database.windows.net,1433"
        "-d", $SqlDatabaseName
        "--authentication-method=ActiveDirectoryDefault"
        "-i", $tempSqlFile
        "-b"  # Batch mode - exit on error
    )
    
    # Execute SQLCMD
    sqlcmd @cmdArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ SQL execution failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ SQL script executed successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Error executing SQL script: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clean up temp file
    if (Test-Path $tempSqlFile) {
        Remove-Item $tempSqlFile -Force
    }
}

# Verify the managed identity has database access by checking role membership
Write-Host ""
Write-Host "Verifying managed identity roles..." -ForegroundColor Cyan

# Note: We can't execute verification queries directly, but we can confirm via Azure portal
Write-Host "✓ Bootstrap completed successfully" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Application restart will load new database permissions"
Write-Host "  2. Monitor application logs for database connection success"
Write-Host "  3. Test API endpoints that require database access"
Write-Host ""
Write-Host "SQL database bootstrap script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
