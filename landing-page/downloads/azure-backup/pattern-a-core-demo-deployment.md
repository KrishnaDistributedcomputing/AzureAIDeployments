# Pattern A: Core Demo Environment - Spec-Driven Deployment

Spec ID: `AZB-SDD-PATTERN-A-CORE-DEMO`

Use case: sales engineering, customer engineering, solution architecture, and executive technical demos.

## Objective

Deploy a compact Azure Backup demo that protects one Azure VM and one Azure file share with a Recovery Services vault, short-retention policies, Log Analytics diagnostics, and a simple restore workflow.

## Resources

| Scope | Name |
|---|---|
| Core resource group | `rg-backup-demo-core` |
| Protection resource group | `rg-backup-demo-protection` |
| Operations resource group | `rg-backup-demo-ops` |
| Recovery Services vault | `rsv-backup-demo-cc` |
| VM | `vm-win-backup-demo-01` |
| Storage account | `stbackupdemo<unique>` |
| File share | `demo-share` |
| Log Analytics workspace | `law-backup-demo-cc` |
| VM policy | `pol-vm-daily-demo` |
| Azure Files policy | `pol-files-daily-demo` |

## Required Tags

```yaml
Environment: Demo
Workload: AzureBackup
Owner: <owner-name>
CostCenter: Demo
AutoDeleteAfter: <yyyy-mm-dd>
SpecDrivenDeployment: AzureBackupDemo
UseCase: CoreDemo
DataClassification: Demo
BusinessCriticality: Low
CleanupRequired: true
```

## Pattern Switches

```yaml
deployWindowsVm: true
deployLinuxVm: false
deployAzureFiles: true
deployBackupVault: false
deployDiskBackup: false
enableSoftDelete: true
enableImmutableVault: false
retentionDays: 7
storageRedundancy: LRS
```

## Deploy

```powershell
cd azure-backup-demo-spec
az login
az account set --subscription "<subscription-name-or-id>"

az provider register --namespace Microsoft.RecoveryServices
az provider register --namespace Microsoft.DataProtection
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.OperationalInsights

$adminPassword = Read-Host -AsSecureString "VM admin password"

./scripts/deploy.ps1 `
  -Location canadacentral `
  -EnvironmentName backup-demo `
  -Owner "<owner-name>" `
  -RegionCode cc `
  -AutoDeleteAfter "<yyyy-mm-dd>" `
  -AdminUsername azureadmin `
  -AdminPassword $adminPassword
```

## Seed, Protect, Validate

```powershell
$CoreResourceGroupName = "rg-backup-demo-core"
$ProtectionResourceGroupName = "rg-backup-demo-protection"
$VaultName = "rsv-backup-demo-cc"
$VmName = "vm-win-backup-demo-01"
$FileShareName = "demo-share"
$StorageAccountName = az storage account list --resource-group $CoreResourceGroupName --query "[?starts_with(name, 'stbackupdemo')].name | [0]" -o tsv

./scripts/seed-demo-data.ps1 -ResourceGroupName $CoreResourceGroupName -StorageAccountName $StorageAccountName -FileShareName $FileShareName

./scripts/trigger-backup.ps1 `
  -CoreResourceGroupName $CoreResourceGroupName `
  -ProtectionResourceGroupName $ProtectionResourceGroupName `
  -VaultName $VaultName `
  -VmName $VmName `
  -StorageAccountName $StorageAccountName `
  -FileShareName $FileShareName `
  -RetainUntil (Get-Date).AddDays(7)

./scripts/validate-backup.ps1 -ProtectionResourceGroupName $ProtectionResourceGroupName -VaultName $VaultName
```

## Restore Demo

Show one restore path: VM file recovery, restore disks, or Azure Files item restore.

## Acceptance

- VM and Azure file share are protected.
- Recovery point exists.
- Backup job is visible.
- One restore path is demonstrated.
- Log Analytics shows backup activity.
- Cleanup is tested.

## Cleanup

```powershell
./scripts/cleanup.ps1 -Force
```
