# Pattern D: Enterprise Landing-Zone Integration - Spec-Driven Deployment

Spec ID: `AZB-SDD-PATTERN-D-ENTERPRISE-LZ`

Use case: production-readiness conversations with enterprise architecture, landing-zone owners, security, operations, FinOps, and workload teams.

## Objective

Convert an Azure Backup demo pattern into an enterprise-ready deployment spec with approved naming, tags, policy assignments, RBAC, diagnostics, private access options, cost controls, and operational handoff.

## Resources

| Scope | Name Pattern |
|---|---|
| Workload resource group | `rg-<workload>-<env>-<region>` |
| Protection resource group | `rg-<workload>-backup-<env>-<region>` |
| Operations resource group | `rg-<workload>-ops-<env>-<region>` |
| Recovery Services vault | `rsv-<workload>-<env>-<region>` |
| Backup vault | `bv-<workload>-<env>-<region>` |
| Log Analytics workspace | `law-<workload>-<env>-<region>` |
| Backup policy | `pol-<workload>-<frequency>-<env>` |
| Required-tags policy assignment | `pa-backup-required-tags-<env>` |
| Diagnostic policy assignment | `pa-backup-diagnostics-<env>` |

## Required Tags

```yaml
Environment: <dev|test|prod|demo>
Workload: AzureBackup
Application: <application-name>
Owner: <owner-name>
CostCenter: <cost-center>
DataClassification: <Public|Internal|Confidential>
BusinessCriticality: <Low|Medium|High>
RPO: <target>
RTO: <target>
Retention: <policy-name-or-duration>
OperationsOwner: <team-name>
SecurityOwner: <team-name>
ComplianceScope: <none|pci|hipaa|sox|custom>
AutoDeleteAfter: <date-if-demo>
```

## Pattern Switches

Choose the workload switches from Pattern A, B, or C, then add enterprise controls.

```yaml
deployWindowsVm: true
deployAzureFiles: true
deployBackupVault: true
enableSoftDelete: true
enableImmutableVault: false
alertEmail: <ops-email>
backupAdminPrincipalId: <group-object-id>
restoreOperatorPrincipalId: <group-object-id>
securityReviewerPrincipalId: <group-object-id>
```

## Deploy Demo Baseline

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
  -AlertEmail "<ops-email>" `
  -AdminPassword $adminPassword
```

## Enterprise Controls To Add Before Production

| Control | Required decision |
|---|---|
| RPO/RTO | Approved by workload owner and business continuity owner. |
| Retention | Daily, weekly, monthly, yearly retention based on compliance and cost. |
| Policy | Required tags, allowed regions, diagnostics, public IP restriction, storage posture. |
| RBAC | Backup Contributor, Backup Operator, Backup Reader assigned to groups only. |
| Network | Bastion and private endpoint design where justified. |
| Monitoring | Central Log Analytics, alerts, workbook, operational ownership. |
| Cost | Protected-instance estimate, retained-data estimate, restored-resource lifecycle. |

## Validate

```powershell
./scripts/validate-backup.ps1 -ProtectionResourceGroupName rg-backup-demo-protection -VaultName rsv-backup-demo-cc
```

Production validation must also include restore testing, policy compliance review, RBAC evidence, cost review, and monitoring handoff.

## Acceptance

- Backup design maps to CAF governance, security, operations, and cost controls.
- Required tags and policies are approved.
- RBAC groups are assigned at the correct scopes.
- Monitoring and alert routing are operational.
- Restore validation is documented.
- Cleanup or lifecycle ownership is documented.

## Cleanup For Demo Baseline

```powershell
./scripts/cleanup.ps1 -Force
```
