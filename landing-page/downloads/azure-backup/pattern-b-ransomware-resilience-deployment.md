# Pattern B: Ransomware-Resilience Showcase - Spec-Driven Deployment

Spec ID: `AZB-SDD-PATTERN-B-RANSOMWARE-RESILIENCE`

Use case: security, business continuity, and operations demos focused on backup deletion protection, role separation, alerting, and restore control.

## Objective

Deploy the core Azure Backup demo with additional emphasis on soft delete, RBAC personas, alert routing, protected recovery points, and immutable vault guidance.

## Resources

| Scope | Name |
|---|---|
| Core resource group | `rg-backup-demo-core` |
| Protection resource group | `rg-backup-demo-protection` |
| Operations resource group | `rg-backup-demo-ops` |
| Recovery Services vault | `rsv-backup-demo-cc` |
| Optional Backup vault | `bv-backup-demo-cc` |
| Action group | `ag-backup-demo` |
| Log Analytics workspace | `law-backup-demo-cc` |
| Backup admin group | `grp-backup-demo-admins` |
| Restore operator group | `grp-backup-demo-restore-operators` |
| Security reviewer group | `grp-backup-demo-security-readers` |

## Required Tags

```yaml
Environment: Demo
Workload: AzureBackup
Owner: <owner-name>
CostCenter: SecurityDemo
AutoDeleteAfter: <yyyy-mm-dd>
SpecDrivenDeployment: AzureBackupDemo
UseCase: RansomwareResilience
DataProtectionTier: Critical
SecurityScenario: SoftDelete-RBAC-Immutability
CleanupRequired: true
```

## Pattern Switches

```yaml
deployWindowsVm: true
deployAzureFiles: true
deployBackupVault: true
deployDiskBackup: false
enableSoftDelete: true
enableImmutableVault: false
alertEmail: <optional-ops-email>
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
  -AlertEmail "<optional-ops-email>" `
  -AdminPassword $adminPassword
```

Do not use `-EnableImmutableVault` for a disposable demo unless teardown has been tested with immutable settings enabled.

## RBAC Personas

| Persona | Azure role | Scope |
|---|---|---|
| Backup Admin | Backup Contributor | Recovery Services vault |
| Restore Operator | Backup Operator | Recovery Services vault |
| Security Reviewer | Reader + Backup Reader | Protection and operations scopes |

## Validate

```powershell
./scripts/trigger-backup.ps1 -ProtectionResourceGroupName rg-backup-demo-protection -VaultName rsv-backup-demo-cc -VmName vm-win-backup-demo-01
./scripts/validate-backup.ps1 -ProtectionResourceGroupName rg-backup-demo-protection -VaultName rsv-backup-demo-cc
```

## Demo Flow

1. Show protected VM and file share.
2. Show soft delete state and explain recovery from accidental or malicious delete.
3. Show role separation for backup admin, restore operator, and security reviewer.
4. Show failed-job or protection-change alert path.
5. Use a pre-staged recovery point to demonstrate restore control.

## Acceptance

- Soft delete is enabled and visible.
- Role separation is documented.
- Alert path is visible.
- Recovery point exists before the demo.
- Presenter can explain immutable vault cleanup caveat.

## Cleanup

```powershell
./scripts/cleanup.ps1 -Force
```
