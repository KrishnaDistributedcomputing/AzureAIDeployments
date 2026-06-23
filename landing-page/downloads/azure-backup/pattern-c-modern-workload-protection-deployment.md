# Pattern C: Modern Workload Protection - Spec-Driven Deployment

Spec ID: `AZB-SDD-PATTERN-C-MODERN-WORKLOADS`

Use case: platform engineering and cloud operations teams evaluating Backup vault, Azure Disk Backup, AKS Backup, Blob operational backup, and modern data-source protection patterns.

## Objective

Deploy a Backup vault-centered demonstration that explains how modern Azure Backup workloads differ from classic Recovery Services vault workloads.

## Resources

| Scope | Name |
|---|---|
| Core resource group | `rg-backup-demo-core` |
| Protection resource group | `rg-backup-demo-protection` |
| Operations resource group | `rg-backup-demo-ops` |
| Backup vault | `bv-backup-demo-cc` |
| Optional Recovery Services vault | `rsv-backup-demo-cc` |
| Optional managed disk | `disk-backup-demo-optional-01` |
| Log Analytics workspace | `law-backup-demo-cc` |
| Disk policy | `pol-disk-hourly-demo` |
| AKS policy placeholder | `pol-aks-daily-demo` |
| Blob operational policy placeholder | `pol-blob-operational-demo` |

## Required Tags

```yaml
Environment: Demo
Workload: AzureBackup
Owner: <owner-name>
CostCenter: PlatformDemo
AutoDeleteAfter: <yyyy-mm-dd>
SpecDrivenDeployment: AzureBackupDemo
UseCase: ModernWorkloadProtection
VaultPattern: BackupVault
DataClassification: Demo
BusinessCriticality: Medium
CleanupRequired: true
```

## Pattern Switches

```yaml
deployBackupVault: true
deployDiskBackup: true
deployWindowsVm: true
deployAzureFiles: false
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

$adminPassword = Read-Host -AsSecureString "VM admin password"

./scripts/deploy.ps1 `
  -Location canadacentral `
  -EnvironmentName backup-demo `
  -Owner "<owner-name>" `
  -RegionCode cc `
  -AutoDeleteAfter "<yyyy-mm-dd>" `
  -DeployDiskBackup `
  -AdminPassword $adminPassword
```

## Workload Mapping

| Workload | Vault pattern | Demo note |
|---|---|---|
| Azure Disk Backup | Backup vault | Use this as the main Pattern C proof point. |
| AKS Backup | Backup vault | Validate region and extension support before demo. |
| Blob operational backup | Operational backup | Explain container-level recovery and storage data protection. |
| VM and Azure Files | Recovery Services vault | Use only as a comparison to classic workloads. |

## Validate

```powershell
./scripts/validate-backup.ps1 -ProtectionResourceGroupName rg-backup-demo-protection -VaultName rsv-backup-demo-cc
```

Also confirm that `bv-backup-demo-cc` exists and sends diagnostics to `law-backup-demo-cc`.

## Acceptance

- Backup vault is deployed.
- Optional disk backup substrate is present.
- Team can explain Backup vault versus Recovery Services vault.
- Operational backup and vaulted backup are clearly differentiated.
- Unsupported workloads are documented as extension notes.

## Cleanup

```powershell
./scripts/cleanup.ps1 -Force
```
