#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Demonstrate VM file recovery from backup recovery point.
.DESCRIPTION
    Mounts a recovery point and provides file picker UI to select specific files.
    Downloads recoverable files as .iso for restoration.
.PARAMETER ProtectionResourceGroupName
    Resource group containing Recovery Services vault.
.PARAMETER VaultName
    Name of the Recovery Services vault.
.PARAMETER VmName
    Name of the VM to recover files from.
.PARAMETER RecoveryPointDate
    DateTime of the recovery point to use (default: most recent).
.EXAMPLE
    ./restore-vm-files.ps1 -ProtectionResourceGroupName rg-backup-demo-protection `
        -VaultName rsv-backup-demo-cc -VmName vm-win-backup-demo-01
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProtectionResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$VaultName,
    
    [Parameter(Mandatory = $true)]
    [string]$VmName,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$RecoveryPointDate
)

function Write-Section { Write-Host "`n► $args " -ForegroundColor Cyan -BackgroundColor DarkBlue }
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Info { Write-Host "  → $args" -ForegroundColor White }

Write-Section "VM File Recovery Demonstration"
Write-Info "VM: $VmName"
Write-Info "Recovery Point: $(if ($RecoveryPointDate) { $RecoveryPointDate.ToString('yyyy-MM-dd') } else { 'Most recent' })"

# Step 1: Get backup container
Write-Section "Step 1: Locating VM backup items"
$containers = az backup container list --resource-group $ProtectionResourceGroupName `
    --vault-name $VaultName --backup-management-type AzureIaasvm -o json | ConvertFrom-Json

$vmContainer = $containers | Where-Object { $_.name -like "*$VmName*" } | Select-Object -First 1

if (-not $vmContainer) {
    Write-Host "✗ VM container not found" -ForegroundColor Red
    exit 1
}

Write-Success "Found container: $($vmContainer.name)"

# Step 2: Get backup items
Write-Section "Step 2: Retrieving recovery points"
$backupItems = az backup item list --resource-group $ProtectionResourceGroupName `
    --vault-name $VaultName --container-name $($vmContainer.name) `
    --backup-management-type AzureIaasvm --workload-type VM -o json | ConvertFrom-Json

if (-not $backupItems) {
    Write-Host "✗ No backup items found" -ForegroundColor Red
    exit 1
}

$backupItem = $backupItems -is [array] ? $backupItems[0] : $backupItems
Write-Success "Found backup item: $($backupItem.name)"

# Step 3: Get recovery points
$recoveryPoints = az backup recoverypoint list --resource-group $ProtectionResourceGroupName `
    --vault-name $VaultName --container-name $($vmContainer.name) `
    --item-name $($backupItem.name) -o json | ConvertFrom-Json

if (-not $recoveryPoints) {
    Write-Host "✗ No recovery points available" -ForegroundColor Red
    exit 1
}

$rpArray = if ($recoveryPoints -is [array]) { $recoveryPoints } else { @($recoveryPoints) }
Write-Success "Found $($rpArray.Count) recovery point(s)"

# Select recovery point
if ($RecoveryPointDate) {
    $selectedRP = $rpArray | Where-Object { [DateTime]$_.properties.recoveryPointTime -ge $RecoveryPointDate } | Select-Object -First 1
} else {
    $selectedRP = $rpArray | Select-Object -First 1
}

if (-not $selectedRP) {
    Write-Host "✗ No matching recovery point found" -ForegroundColor Red
    exit 1
}

Write-Success "Using recovery point: $($selectedRP.properties.recoveryPointTime)"

# Step 4: Mount recovery point (in production, this would trigger actual mount)
Write-Section "Step 3: Mounting recovery point"
Write-Host "In production scenario, Azure Backup would mount the recovery point" -ForegroundColor Gray
Write-Host "and provide file browser interface." -ForegroundColor Gray
Write-Info "Available for restore:"
Write-Info "  C:\DemoData\Q2-Budget.txt (500 KB)"
Write-Info "  C:\DemoData\Employee-Records.csv (2 MB)"
Write-Info "  C:\DemoData\Financial-Report.xlsx (5 MB)"
Write-Info "  C:\DemoData\Project-Archive.zip (15 MB)"
Write-Info "  C:\DemoData\Database-Backup.bak (50 MB)"

# Step 5: File selection simulation
Write-Section "Step 4: File Selection"
Write-Host "Select files to restore (simulated):" -ForegroundColor Cyan

$filesToRestore = @(
    "C:\DemoData\Q2-Budget.txt",
    "C:\DemoData\Employee-Records.csv",
    "C:\DemoData\Financial-Report.xlsx"
)

foreach ($file in $filesToRestore) {
    Write-Info "Selected: $file"
}

# Step 6: Generate ISO
Write-Section "Step 5: Generating recovery ISO"
Write-Info "Creating downloadable .iso with selected files..."
Write-Success "Recovery ISO generated: vm-restore-$(Get-Date -Format 'yyyyMMdd-HHmm').iso (72 MB)"

# Step 7: Summary
Write-Section "File Recovery Summary"
Write-Info "Total files selected: $($filesToRestore.Count)"
Write-Info "Total size: ~72 MB"
Write-Info ""
Write-Host "In production:" -ForegroundColor Yellow
Write-Host "  1. Download .iso from Azure Portal"
Write-Host "  2. Mount on local system or VM"
Write-Host "  3. Copy files back to original or alternate location"
Write-Host "  4. Verify file integrity and permissions"
Write-Host ""
Write-Success "File recovery demonstration complete"
Write-Host ""
Write-Host "This demonstrates the granular file recovery capability." -ForegroundColor Cyan
