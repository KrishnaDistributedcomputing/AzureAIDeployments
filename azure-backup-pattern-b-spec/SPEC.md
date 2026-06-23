# Spec-Driven Development: Azure Backup Pattern B — Ransomware Resilience

Document version: 1.0

Target audience: Security stakeholders, business continuity managers, ransomware incident response teams, backup administrators

Primary objective: Demonstrate Azure Backup's ransomware-resilience controls, including role-based access control (RBAC) separation, soft delete protections, immutable vault designs, and automated alerting for security incidents. This pattern is designed for organizations prioritizing recovery speed and deletion protection.

## Deployment scope

This implementation provides a production-grade baseline for ransomware-resilience scenarios:

- **Separate resource groups** for workload, protection, and security operations
- **Demo VM substrate** with encrypted OS and data disks (ADE optional)
- **Azure file share** with snapshot-based protection and point-in-time recovery
- **Recovery Services vault** with:
  - Soft delete enabled (14-day retention for deleted items)
  - Immutable vault lock enabled (prevents deletion of backup data)
  - Diagnostic logging to Security Operations Center (SOC) integration
- **RBAC role assignments**:
  - `Backup Operator` (limited to backup trigger/restore initiation)
  - `Backup Administrator` (vault configuration, policy, retention management)
  - `Restore Operator` (restore workflows only, no backup policy changes)
  - `Audit Reader` (read-only access for compliance/SOC teams)
- **Azure Monitor action groups** with webhook/email alerts for:
  - Backup job failures
  - Restore operations initiated
  - Vault deletion attempts
  - Soft delete operations triggered
- **Log Analytics workspace** with KQL queries for:
  - Ransomware detection patterns (multiple failed backups, unusual restore patterns)
  - Role-based access audit trail
  - Incident timeline reconstruction
- **Pre-staged recovery point** for immediate restore demonstration without waiting for backup job completion
- **Optional** Private Endpoint for vault access isolation in hybrid/on-premises scenarios

## Demo defaults

| Parameter | Default | Rationale |
|---|---|---|
| environmentName | backup-resilience | Indicates security/resilience focus |
| location | canadacentral | Regional redundancy for recovery |
| owner | security-team | SOC ownership for compliance |
| deployWindowsVm | true | Ransomware target scenario |
| deployLinuxVm | false | Optional for Bash-based workloads |
| deployAzureFiles | true | File-share encryption & snapshots |
| enableSoftDelete | true | **Required** — 14-day item recovery |
| enableImmutableVault | true | **Required** — deletion protection lock |
| enablePrivateEndpoint | false | Optional: VNet isolation for air-gapped backups |
| softDeleteRetentionDays | 14 | Minimum protection window |
| immutableVaultLockDuration | Unlimited | Permanent lock prevents vault deletion |
| alertThresholdFailures | 3 | Trigger alert on 3+ failed backup jobs |
| retentionDays | 7 | Short retention (pattern focuses on recovery speed) |
| storageRedundancy | GRS | Geo-redundant protection against regional loss |

## Architecture

### Network

```
┌─────────────────────────────────────────┐
│ Workload Resource Group                 │
│ ┌────────────────┐                      │
│ │ Windows VM     │                      │
│ │ (Encrypted)    │                      │
│ ├─ OS Disk       │                      │
│ └─ Data Disk (D:)│                      │
│ ┌────────────────┐                      │
│ │ Storage Acct   │                      │
│ │ Azure Files    │                      │
│ └────────────────┘                      │
└─────────────────────────────────────────┘
           ↓ (Backup Agent)
┌─────────────────────────────────────────┐
│ Protection Resource Group               │
│ ┌────────────────────────────────────┐  │
│ │ Recovery Services Vault            │  │
│ │ ✓ Soft Delete (14 days)            │  │
│ │ ✓ Immutable Vault Lock             │  │
│ │ ✓ Geo-Redundant Storage            │  │
│ └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
           ↓ (Diagnostics)
┌─────────────────────────────────────────┐
│ Operations Resource Group               │
│ ┌────────────────────────────────────┐  │
│ │ Log Analytics Workspace            │  │
│ │ ✓ Backup Job Events               │  │
│ │ ✓ Restore Operations              │  │
│ │ ✓ Vault Access Logs               │  │
│ └────────────────────────────────────┘  │
│ ┌────────────────────────────────────┐  │
│ │ Azure Monitor Action Group         │  │
│ │ ✓ Email/SMS/Webhook Alerts        │  │
│ └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### RBAC Separation Model

| Role | Permissions | Use Case | Risk Level |
|---|---|---|---|
| **Backup Operator** | Start backup, start restore (restore only, no configuration) | Daily backup triggers, manual recovery operations | LOW — limited to execution |
| **Backup Administrator** | Full vault management, policy creation, retention configuration, soft delete management | Vault design, policy tuning, retention decisions | HIGH — can modify vault settings |
| **Restore Operator** | Restore workflows only, view recovery points, cannot trigger backups or modify policies | Incident response, file recovery | MEDIUM — limited to recovery |
| **Audit Reader** | Read-only access to vault, policies, diagnostic logs | SOC, compliance, audit teams | LOW — read-only |

**Key Separation Principle**: The account that triggers backups cannot manage vault settings, preventing ransomware actor from disabling protections after compromise.

## Backup policies

### VM Backup Policy (Daily, 7-day retention)

```
Name: resilience-vm-daily
Frequency: Daily @ 11:00 PM UTC
Retention: 7 days (daily snapshots)
Instant restore snapshots: 5 days
Soft delete: Enabled (14-day recovery)
```

### Azure Files Policy (Snapshot-based, 30-day retention)

```
Name: resilience-files-daily
Frequency: Daily @ 12:30 AM UTC
Snapshot retention: 30 days
Soft delete: Enabled (14-day recovery)
GRS replication: Enabled
```

## Restore workflows (for demo)

1. **File-level restore** (fastest, typical use case)
   - Demonstrate recovery of 3 files from day-old snapshot
   - Show point-in-time selection
   - Browser-based file selection

2. **Disk restore** (full recovery test)
   - Restore encrypted data disk to alternate VM
   - Verify disk integrity and encryption
   - Demonstrate restore speed (typically < 10 minutes)

3. **Soft delete recovery** (ransomware-specific)
   - Delete a backup recovery point
   - Show 14-day undelete window
   - Restore from "soft-deleted" backup
   - **Presenter note**: "Even if attacker deletes backups, we can recover them for 14 days"

## Monitoring & alerting

### KQL Queries (Log Analytics)

**Query 1: Backup Failures in Last 24 Hours**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName in ("Backup", "BackupJob")
| where Status == "Failed"
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationName, Status, BackupItemFriendlyName, Details
| order by TimeGenerated desc
```

**Query 2: Access Audit Trail (RBAC Activities)**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName in ("CreateVault", "DeleteVault", "UpdateVault", "EnableSoftDelete")
| project TimeGenerated, Caller, OperationName, ResourceName, Status
| order by TimeGenerated desc
```

**Query 3: Soft Delete Operations (Ransomware Indicator)**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName == "SoftDelete"
| project TimeGenerated, CallerIPAddress, Caller, ResourceName, Details
| order by TimeGenerated desc
```

### Alert Rules

| Alert Name | Condition | Action |
|---|---|---|
| **Backup Job Failure** | 3+ failed jobs in 1 hour | Email SOC + Webhook to SIEM |
| **Vault Deletion Attempt** | Any DeleteVault operation | Immediate Slack + PagerDuty |
| **Soft Delete Triggered** | SoftDelete operation observed | Log to SOC dashboard |
| **Unauthorized Restore** | Restore initiated by non-Restore-Operator account | Email audit team |

## Definition of done

The demonstration is complete when:

- ✅ Both resource groups deploy without errors (workload and protection)
- ✅ RBAC roles assigned correctly (verify Backup Operator cannot modify policy)
- ✅ Soft delete enabled and 14-day retention confirmed in vault properties
- ✅ Immutable vault lock applied and lock date visible
- ✅ At least one backup job triggered and recovery point visible
- ✅ File-level restore demonstrated (download and restore 3 files)
- ✅ Soft delete recovery demonstrated (delete recovery point and undelete)
- ✅ Azure Monitor alert triggered for test failure (intentionally fail 3 jobs)
- ✅ Log Analytics queries return expected events for access audit trail
- ✅ Presenter explains deletion protection, role separation, and restore control flow
- ✅ All resources cleaned up and cost incurred documented

## Presenter talking points

1. **Deletion protection layers**: Soft delete (14 days) + immutable vault lock (permanent) = two-layer protection
2. **Role separation prevents "insider" attacks**: Operator who can restore cannot disable backups
3. **Ransomware recovery time**: Files restored in < 5 minutes, full disk in < 15 minutes
4. **Compliance story**: Immutable lock proves backup integrity for audit (SOX, HIPAA, PCI-DSS)
5. **Cost trade-off**: Immutable vault cannot lower retention (costs more), but recovery is guaranteed

## Parameters (for Bicep deployment)

```bicep
param environmentName string = 'backup-resilience'
param location string = 'canadacentral'
param owner string = 'security-team'
param deployWindowsVm bool = true
param enableSoftDelete bool = true
param enableImmutableVault bool = true
param softDeleteRetentionDays int = 14
param alertEmail string = 'soc@company.com'
param restoreOperatorObjectId string = '' // Azure AD group or user
param auditReaderObjectId string = ''
```

## Dependencies & prerequisites

- Azure subscription with Recovery Services resource provider registered
- Azure CLI >= 2.45.0 or PowerShell 7+
- User with Subscription Contributor role for initial deployment
- Log Analytics workspace for diagnostics (auto-created or reference existing)
- Azure AD group or service principal for role assignments

## Success criteria

Pattern B demonstration is successful when:

1. **Security**: Role-based access prevents unauthorized backup modifications
2. **Resilience**: Soft delete and immutable lock prevent ransomware deletion
3. **Speed**: File restore completes in < 5 minutes, disk restore in < 15 minutes
4. **Compliance**: Audit trail shows all vault operations and access patterns
5. **Narrative**: Presenter confidently explains ransomware recovery scenario and role separation model
