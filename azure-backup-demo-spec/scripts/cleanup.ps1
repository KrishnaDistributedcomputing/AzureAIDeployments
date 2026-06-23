param(
  [string[]]$ResourceGroupNames = @('rg-backup-demo-core', 'rg-backup-demo-protection', 'rg-backup-demo-ops'),
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not $Force) {
  Write-Warning 'This deletes the Azure Backup demo resource groups. Confirm that soft-delete, immutable vault, and restored resource cleanup implications are understood.'
  $confirmation = Read-Host 'Type DELETE to continue'
  if ($confirmation -ne 'DELETE') {
    Write-Host 'Cleanup cancelled.'
    exit 0
  }
}

foreach ($resourceGroupName in $ResourceGroupNames) {
  Write-Host "Deleting $resourceGroupName..."
  az group delete --name $resourceGroupName --yes --no-wait
}

Write-Host 'Delete operations submitted. Check Azure portal or az group exists for completion.'
