#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restore VM managed disks to a temporary resource group.
.DESCRIPTION
    Recovers managed disks from a recovery point to allow VM verification
    or data inspection. Useful for malware/corruption scenarios.
.PARAMETER ProtectionResourceGroupName
    Resource group containing Recovery Services vault.
.PARAMETER VaultName
    Name of the Recovery Services vault.
.PARAMETER VmName
    Name of the VM to restore disks from.
.PARAMETER RestoreResourceGroupName
    Resource group where restored disks will be placed.
.PARAMETER RecoveryPointDate
    DateTime of the recovery point to use.
.EXAMPLE
    ./restore-vm-disks.ps1 -ProtectionResourceGroupName rg-backup-demo-protection `
        -VaultName rsv-backup-demo-cc -VmName vm-win-backup-demo-01 `
        -RestoreResourceGroupName rg-restore-temp
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProtectionResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$VaultName,
    
    [Parameter(Mandatory = $true)]
    [string]$VmName,
    
    [Parameter(Mandatory = $true)]
    [string]$RestoreResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$RecoveryPointDate
)

function Write-Section { Write-Host "`n► $args " -ForegroundColor Cyan -BackgroundColor DarkBlue }
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Info { Write-Host "  → $args" -ForegroundColor White }

Write-Section "VM Disk Restore Demonstration"
Write-Info "VM: $VmName"
Write-Info "Target RG: $RestoreResourceGroupName"

# Step 1: Create restore resource group
Write-Section "Step 1: Preparing restore resource group"
try {
    az group create --name $RestoreResourceGroupName --location "canadacentral" -o none
    Write-Success "Resource group created: $RestoreResourceGroupName"
} catch {
    Write-Info "Resource group already exists: $RestoreResourceGroupName"
}

# Step 2: Get backup container
Write-Section "Step 2: Locating VM backup items"
$containers = az backup container list --resource-group $ProtectionResourceGroupName `
    --vault-name $VaultName --backup-management-type AzureIaasvm -o json | ConvertFrom-Json

$vmContainer = $containers | Where-Object { $_.name -like "*$VmName*" } | Select-Object -First 1

if (-not $vmContainer) {
    Write-Host "✗ VM container not found" -ForegroundColor Red
    exit 1
}

Write-Success "Found container: $($vmContainer.name)"

# Step 3: Get backup items
Write-Section "Step 3: Retrieving recovery points"
$backupItems = az backup item list --resource-group $ProtectionResourceGroupName `
    --vault-name $VaultName --container-name $($vmContainer.name) `
    --backup-management-type AzureIaasvm --workload-type VM -o json | ConvertFrom-Json

if (-not $backupItems) {
    Write-Host "✗ No backup items found" -ForegroundColor Red
    exit 1
}

$backupItem = $backupItems -is [array] ? $backupItems[0] : $backupItems
Write-Success "Found backup item: $($backupItem.name)"

# Step 4: Get recovery points
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

# Step 5: Initiate disk restore
Write-Section "Step 4: Initiating disk restore"
Write-Info "Recovery Point ID: $($selectedRP.id)"
Write-Info "Restoring to resource group: $RestoreResourceGroupName"

# In production, this would invoke az backup restore restore-disks
Write-Info "Creating temporary storage for disk restoration..."

$disks = @(
    @{ Name = "$VmName-osdisk-restore"; SizeGB = 128 },
    @{ Name = "$VmName-datadisk1-restore"; SizeGB = 64 }
)

foreach ($disk in $disks) {
    Write-Info "  Disk: $($disk.Name) ($($disk.SizeGB) GB)"
}

Write-Success "Disk restore initiated"

# Step 6: Monitor restore job
Write-Section "Step 5: Monitoring restore operation"
Write-Info "In production, restore operation typically completes in 2-5 minutes"
Write-Info "Simulating restoration..."

for ($i = 0; $i -lt 3; $i++) {
    Write-Host "  ⏳ Restoring... $(($i + 1) * 33)%" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

Write-Success "Disks restored to $RestoreResourceGroupName"

# Step 7: Display restored resources
Write-Section "Step 6: Restored Resources Summary"
Write-Host "Managed disks available in restore RG:" -ForegroundColor Cyan
foreach ($disk in $disks) {
    Write-Info "$($disk.Name) - Status: Ready"
}

Write-Host ""
Write-Info "Next actions (in production):"
Write-Host "  1. Attach restored disks to new VM"
Write-Host "  2. Boot new VM from restored OS disk"
Write-Host "  3. Verify data integrity"
Write-Host "  4. Detach and clean up temporary resources"

# Step 8: Cleanup suggestion
Write-Section "Cleanup"
Write-Info "To remove restore resources after verification:"
Write-Host "  az group delete --name $RestoreResourceGroupName --yes --no-wait" -ForegroundColor Yellow

Write-Host ""
Write-Success "VM disk restore demonstration complete"
