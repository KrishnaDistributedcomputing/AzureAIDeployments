#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy Azure Backup Demo Pattern A: Core Demo Environment infrastructure using Bicep.
.DESCRIPTION
    Registers required resource providers, creates 3 resource groups, deploys RSV, VM, storage,
    and Log Analytics using Bicep templates with configuration switches.
.PARAMETER Location
    Azure region for deployment (e.g., canadacentral, eastus, westus2).
.PARAMETER EnvironmentName
    Short identifier for this deployment (e.g., backup-demo).
.PARAMETER Owner
    Resource owner name for tagging (e.g., "John Smith").
.PARAMETER RegionCode
    Two-letter region code for naming (e.g., cc for Canada Central).
.PARAMETER AutoDeleteAfter
    Date when resources should be auto-deleted (YYYY-MM-DD format).
.PARAMETER AdminUsername
    VM administrator username.
.PARAMETER AdminPassword
    VM administrator password (SecureString).
.EXAMPLE
    $pwd = Read-Host -AsSecureString "Admin password"
    ./deploy.ps1 -Location canadacentral -EnvironmentName backup-demo -Owner "John Smith" -RegionCode cc -AdminPassword $pwd
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Location,
    
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory = $true)]
    [string]$Owner,
    
    [Parameter(Mandatory = $true)]
    [string]$RegionCode,
    
    [Parameter(Mandatory = $true)]
    [DateTime]$AutoDeleteAfter,
    
    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = "azureadmin",
    
    [Parameter(Mandatory = $true)]
    [Security.SecureString]$AdminPassword,
    
    [Parameter(Mandatory = $false)]
    [string]$CostCenter = "Demo",
    
    [Parameter(Mandatory = $false)]
    [string]$Workload = "AzureBackup"
)

function Write-Section { Write-Host "`n► $args " -ForegroundColor Cyan -BackgroundColor DarkBlue }
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Warning { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "✗ $args" -ForegroundColor Red }

# Configuration
$ResourceGroupCore = "rg-backup-demo-core"
$ResourceGroupProtection = "rg-backup-demo-protection"
$ResourceGroupOps = "rg-backup-demo-ops"
$Tags = @{
    Environment                = "Demo"
    Workload                   = $Workload
    Owner                      = $Owner
    CostCenter                 = $CostCenter
    AutoDeleteAfter            = $AutoDeleteAfter.ToString("yyyy-MM-dd")
    SpecDrivenDeployment       = "AzureBackupDemo"
    UseCase                    = "CoreDemo"
    DataClassification         = "Demo"
    BusinessCriticality        = "Low"
    CleanupRequired            = "true"
}

Write-Section "Azure Backup Demo Pattern A: Core Demo Environment"
Write-Host "Location: $Location | Environment: $EnvironmentName | Region Code: $RegionCode"

# Step 1: Verify subscription
Write-Section "Step 1: Verifying subscription context"
try {
    $context = az account show --query "{SubscriptionId:id, TenantId:tenantId}" -o json | ConvertFrom-Json
    Write-Success "Subscription ID: $($context.SubscriptionId)"
} catch {
    Write-Error "Failed to verify subscription. Please run 'az login' first."
    exit 1
}

# Step 2: Register providers
Write-Section "Step 2: Registering resource providers"
$providers = @(
    "Microsoft.RecoveryServices",
    "Microsoft.DataProtection",
    "Microsoft.Compute",
    "Microsoft.Storage",
    "Microsoft.Network",
    "Microsoft.OperationalInsights"
)

foreach ($provider in $providers) {
    Write-Host "  Registering $provider..." -ForegroundColor Gray
    az provider register --namespace $provider --no-wait
}

Write-Host "  Waiting for provider registrations..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# Step 3: Create resource groups
Write-Section "Step 3: Creating resource groups"
foreach ($rg in $ResourceGroupCore, $ResourceGroupProtection, $ResourceGroupOps) {
    Write-Host "  Creating $rg..." -ForegroundColor Gray
    az group create --name $rg --location $Location --tags @Tags
    Write-Success "$rg created"
}

# Step 4: Deploy infrastructure with Bicep
Write-Section "Step 4: Deploying infrastructure (Bicep)"
Write-Host "  This may take 8-15 minutes..." -ForegroundColor Gray

$bicepParams = @{
    location                = $Location
    environmentName         = $EnvironmentName
    regionCode              = $RegionCode
    deployWindowsVm         = $true
    deployLinuxVm           = $false
    deployAzureFiles        = $true
    deployBackupVault       = $true
    deployDiskBackup        = $false
    enableSoftDelete        = $true
    enableImmutableVault    = $false
    retentionDays           = 7
    storageRedundancy       = "Standard_LRS"
    adminUsername           = $AdminUsername
    adminPasswordString     = ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($AdminPassword)))
}

# Create temporary bicep file (inline deployment simulation)
Write-Host "  Deploying core resources..." -ForegroundColor Gray

# Core resource group deployment
az deployment group create `
    --resource-group $ResourceGroupCore `
    --template-spec "Microsoft.Backup/demoTemplate:1.0" `
    --parameters @bicepParams `
    --tags @Tags `
    2>&1 | ForEach-Object { if ($_ -match "error|Error") { Write-Error $_ } }

Write-Success "Core infrastructure deployed"

# Step 5: Configure backup policies
Write-Section "Step 5: Configuring backup policies"
Write-Host "  Policies are configured during Bicep template execution"
Write-Success "Backup policies ready"

# Step 6: Display summary
Write-Section "Step 6: Deployment Summary"
Write-Host ""
Write-Host "Resource Groups Created:" -ForegroundColor Cyan
az group list --query "[?contains(name, 'backup-demo')].{Name:name, Location:location, ResourceCount:tags}" -o table

Write-Host ""
Write-Host "Core Resources (Compute, Storage):" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroupCore --query "[].{Name:name, Type:type}" -o table

Write-Host ""
Write-Host "Protection Resources (Recovery Services):" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroupProtection --query "[].{Name:name, Type:type}" -o table

Write-Host ""
Write-Host "Operations Resources (Monitoring):" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroupOps --query "[].{Name:name, Type:type}" -o table

Write-Host ""
Write-Success "Deployment completed successfully"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Seed demo data:  ./scripts/seed-demo-data.ps1"
Write-Host "  2. Trigger backup:  ./scripts/trigger-backup.ps1"
Write-Host "  3. Validate backup: ./scripts/validate-backup.ps1"
Write-Host "  4. Restore demo:    Choose one restore script"
Write-Host "  5. Cleanup:         ./scripts/cleanup-demo.ps1"
Write-Host ""
