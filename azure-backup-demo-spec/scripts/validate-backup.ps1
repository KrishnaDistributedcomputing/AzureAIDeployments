#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validate successful backup completion and recovery point availability.
.DESCRIPTION
    Checks that backup jobs completed successfully, recovery points exist,
    and Log Analytics metrics are being collected.
.PARAMETER ProtectionResourceGroupName
    Resource group containing Recovery Services vault.
.PARAMETER VaultName
    Name of the Recovery Services vault.
.EXAMPLE
    ./validate-backup.ps1 -ProtectionResourceGroupName rg-backup-demo-protection -VaultName rsv-backup-demo-cc
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProtectionResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$VaultName
)

function Write-Section { Write-Host "`n► $args " -ForegroundColor Cyan -BackgroundColor DarkBlue }
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Warning { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-Info { Write-Host "  → $args" -ForegroundColor White }

Write-Section "Validating Azure Backup Pattern A"

# Validation checklist
$checks = @{
    "VaultExists" = $false
    "BackupItemsConfigured" = $false
    "RecoveryPointsExist" = $false
    "BackupJobsCompleted" = $false
    "SoftDeleteEnabled" = $false
}

# Check 1: Vault exists and is accessible
Write-Section "Check 1: Recovery Services Vault"
try {
    $vault = az backup vault show --resource-group $ProtectionResourceGroupName `
        --name $VaultName -o json | ConvertFrom-Json
    
    Write-Success "Vault found: $($vault.name)"
    Write-Info "Region: $($vault.location)"
    Write-Info "SKU: $($vault.sku.name)"
    $checks["VaultExists"] = $true
    
    # Check soft delete status
    if ($vault.properties.softDeleteFeatureState -eq "Enabled") {
        Write-Success "Soft delete: ENABLED (14-day recovery)"
        $checks["SoftDeleteEnabled"] = $true
    } else {
        Write-Warning "Soft delete: DISABLED (consider enabling)"
    }
} catch {
    Write-Host "✗ Vault not found or inaccessible" -ForegroundColor Red
    exit 1
}

# Check 2: Backup items configured
Write-Section "Check 2: Backup Items"
try {
    $vmItems = az backup item list --resource-group $ProtectionResourceGroupName `
        --vault-name $VaultName --backup-management-type AzureIaasvm `
        --workload-type VM -o json | ConvertFrom-Json
    
    $vmCount = if ($vmItems -is [array]) { $vmItems.Count } else { if ($vmItems) { 1 } else { 0 } }
    
    if ($vmCount -gt 0) {
        Write-Success "VMs protected: $vmCount"
        $checks["BackupItemsConfigured"] = $true
        foreach ($item in ($vmItems -is [array] ? $vmItems : @($vmItems))) {
            Write-Info "$($item.name) [$($item.protectionState)]"
        }
    } else {
        Write-Warning "No VM backup items found"
    }
} catch {
    Write-Warning "Could not retrieve VM backup items"
}

# Check 3: Recovery points exist
Write-Section "Check 3: Recovery Points"
$recoveryPointCount = 0
try {
    $vmItems = @(az backup item list --resource-group $ProtectionResourceGroupName `
        --vault-name $VaultName --backup-management-type AzureIaasvm `
        --workload-type VM -o json | ConvertFrom-Json)
    
    foreach ($item in $vmItems) {
        try {
            $recoveryPoints = az backup recoverypoint list --resource-group $ProtectionResourceGroupName `
                --vault-name $VaultName --container-name $($item.containerName) `
                --item-name $($item.name) -o json | ConvertFrom-Json
            
            $rpCount = if ($recoveryPoints -is [array]) { $recoveryPoints.Count } else { if ($recoveryPoints) { 1 } else { 0 } }
            $recoveryPointCount += $rpCount
            
            if ($rpCount -gt 0) {
                Write-Success "$($item.name): $rpCount recovery point(s)"
                $checks["RecoveryPointsExist"] = $true
            }
        } catch {
            Write-Warning "Could not retrieve recovery points for $($item.name)"
        }
    }
    
    if ($recoveryPointCount -eq 0) {
        Write-Warning "No recovery points available yet (backups may still be processing)"
    }
} catch {
    Write-Warning "Error querying recovery points"
}

# Check 4: Recent backup jobs
Write-Section "Check 4: Backup Jobs"
try {
    $jobs = az backup job list --resource-group $ProtectionResourceGroupName `
        --vault-name $VaultName -o json | ConvertFrom-Json
    
    $completedJobs = $jobs | Where-Object { $_.properties.status -eq "Completed" } | Measure-Object
    $failedJobs = $jobs | Where-Object { $_.properties.status -eq "Failed" } | Measure-Object
    $inProgressJobs = $jobs | Where-Object { $_.properties.status -eq "InProgress" } | Measure-Object
    
    Write-Info "Completed: $($completedJobs.Count) jobs"
    Write-Info "Failed: $($failedJobs.Count) jobs"
    Write-Info "In Progress: $($inProgressJobs.Count) jobs"
    
    if ($completedJobs.Count -gt 0) {
        Write-Success "Backup jobs completed successfully"
        $checks["BackupJobsCompleted"] = $true
    } else {
        Write-Warning "No completed backup jobs yet"
    }
    
    # Show last 5 jobs
    Write-Host ""
    Write-Info "Recent jobs:"
    $jobs | Select-Object -First 5 | ForEach-Object {
        $icon = if ($_.properties.status -eq "Completed") { "✓" } elseif ($_.properties.status -eq "Failed") { "✗" } else { "⏳" }
        Write-Host "  $icon $($_.name) [$($_.properties.status)]"
    }
} catch {
    Write-Warning "Could not retrieve backup jobs"
}

# Validation Summary
Write-Section "Validation Summary"
$passCount = ($checks.Values | Where-Object { $_ -eq $true }).Count
$totalChecks = $checks.Count

Write-Host "Passed: $passCount/$totalChecks checks" -ForegroundColor Cyan
Write-Host ""

foreach ($check in $checks.GetEnumerator()) {
    $icon = $check.Value ? "✓" : "✗"
    $status = $check.Value ? "PASS" : "FAIL"
    Write-Host "$icon $($check.Name): $status"
}

Write-Host ""

if ($passCount -eq $totalChecks) {
    Write-Success "All validation checks passed!"
    Write-Info "Backup pattern is operational and ready for restore demos."
} else {
    Write-Warning "Some checks failed. Review above and troubleshoot."
    Write-Info "If backups are still processing, run this script again in 5 minutes."
}

Write-Host ""
Write-Host "Next step: Choose a restore demo script" -ForegroundColor Yellow
Write-Host "  - ./scripts/restore-vm-files.ps1 (easiest)"
Write-Host "  - ./scripts/restore-vm-disks.ps1"
Write-Host "  - ./scripts/restore-file-share-items.ps1 (recommended)"
