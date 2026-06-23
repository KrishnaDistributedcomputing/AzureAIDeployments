#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Delete all demo resource groups and cleanup Pattern A deployment.
.DESCRIPTION
    Removes 3 resource groups (core, protection, ops) and their resources.
    Use with caution - this is permanent deletion.
.PARAMETER Force
    Skip confirmation prompts and proceed with deletion.
.PARAMETER NoWait
    Do not wait for deletion to complete, return immediately.
.EXAMPLE
    ./cleanup-demo.ps1 -Force
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoWait
)

function Write-Section { Write-Host "`n► $args " -ForegroundColor Cyan -BackgroundColor DarkBlue }
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Warning { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-Info { Write-Host "  → $args" -ForegroundColor White }

Write-Section "Azure Backup Demo Pattern A: Cleanup"
Write-Host ""

# Resource groups to delete
$resourceGroups = @(
    "rg-backup-demo-core",
    "rg-backup-demo-protection",
    "rg-backup-demo-ops"
)

# Step 1: Display what will be deleted
Write-Section "Resources to Delete"
Write-Host "The following resource groups will be permanently deleted:" -ForegroundColor Red
Write-Host ""
foreach ($rg in $resourceGroups) {
    Write-Host "  • $rg"
}
Write-Host ""

# Step 2: Get resource counts
Write-Section "Resource Summary"
foreach ($rg in $resourceGroups) {
    try {
        $resources = az resource list --resource-group $rg --query "[].type" 2>/dev/null | ConvertFrom-Json
        $count = if ($resources -is [array]) { $resources.Count } else { if ($resources) { 1 } else { 0 } }
        Write-Info "$rg: $count resource(s)"
    } catch {
        Write-Info "$rg: (not found or not accessible)"
    }
}

# Step 3: Confirmation
Write-Host ""
if (-not $Force) {
    $confirmation = Read-Host "⚠ Type 'DELETE' to confirm deletion (or press Enter to cancel)"
    if ($confirmation -ne "DELETE") {
        Write-Host ""
        Write-Info "Cleanup cancelled. No resources deleted."
        exit 0
    }
}

# Step 4: Delete resource groups
Write-Section "Deleting Resource Groups"
foreach ($rg in $resourceGroups) {
    Write-Info "Deleting: $rg..."
    
    if ($NoWait) {
        az group delete --name $rg --yes --no-wait 2>/dev/null
        Write-Success "$rg deletion queued (background)"
    } else {
        try {
            az group delete --name $rg --yes 2>/dev/null
            Write-Success "$rg deleted"
        } catch {
            Write-Warning "$rg not found (already deleted)"
        }
    }
}

# Step 5: Verify cleanup
if (-not $NoWait) {
    Write-Section "Verifying Cleanup"
    Write-Info "Checking for remaining resources..."
    
    $allDeleted = $true
    foreach ($rg in $resourceGroups) {
        $exists = az group exists --name $rg -o json | ConvertFrom-Json
        if ($exists) {
            Write-Warning "$rg still exists (deletion in progress)"
            $allDeleted = $false
        } else {
            Write-Success "$rg confirmed deleted"
        }
    }
    
    if ($allDeleted) {
        Write-Section "Cleanup Complete"
        Write-Success "All demo resources have been successfully deleted."
        Write-Info "This typically costs: $0.00 (all resources removed)"
    } else {
        Write-Section "Cleanup In Progress"
        Write-Warning "Some resources are still being deleted (background operation)"
        Write-Info "Check Azure Portal → Resource Groups for status"
    }
} else {
    Write-Section "Cleanup Initiated"
    Write-Info "Resource groups queued for background deletion"
    Write-Info "Check Azure Portal → Resource Groups for status"
    Write-Info "Deletion typically completes in 3-5 minutes"
}

Write-Host ""
Write-Info "Demo environment has been cleaned up."
Write-Info "No further charges will accrue for demo resources."
