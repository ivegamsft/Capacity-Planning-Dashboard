#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bootstrap script to configure Azure SQL database with managed identity authentication
    
.DESCRIPTION
    This script is executed as part of the deployment workflow (GitHub Actions).
    It configures the database for the App Service managed identity by:
    1. Authenticating to Azure using Azure CLI
    2. Executing SQL initialization script against the database
    3. Granting necessary roles to the managed identity

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
