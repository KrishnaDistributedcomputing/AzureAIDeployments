# Spec-Driven Development: Azure Backup Pattern C — Modern Workloads

Document version: 1.0

Target audience: Platform teams, DevOps engineers, infrastructure architects, cloud center of excellence (CCoE)

Primary objective: Demonstrate Backup vault capabilities and when to use Recovery Services vault vs. Backup vault. This pattern focuses on modern application workloads (AKS, managed disks, Blob storage, Azure App Services) and the differentiated vault strategies required for microservices, containerized applications, and serverless architectures.

## Deployment scope

This implementation demonstrates vault differentiation and modern workload backup patterns:

- **Recovery Services vault** for traditional workloads (VMs, file shares, on-premises servers)
- **Backup vault** (new tier) optimized for:
  - Managed disk backup
  - Azure Kubernetes Service (AKS) cluster backup
  - Azure Blob operational backup (point-in-time recovery)
  - Database-specific backup strategies
- **Demo infrastructure**:
  - Optional managed disk (Premium SSD) for disk backup demonstration
  - Optional AKS cluster with sample workloads for backup/restore demo
  - Optional blob storage account with operational backup policy
  - Log Analytics workspace with workload-specific diagnostics
- **Vault comparison matrix** showing:
  - Which workloads belong in which vault
  - Storage redundancy differences
  - Cost implications per workload type
  - Retention and compliance requirements
- **No RBAC separation** (unlike Pattern B) — focus is on vault architectural differences, not security controls

## Demo defaults

| Parameter | Default | Rationale |
|---|---|---|
| environmentName | backup-modern | Indicates modern workload focus |
| location | eastus | Azure Kubernetes Service availability |
| owner | platform-team | DevOps team ownership |
| deployBackupVault | true | **Key differentiator** — new Backup vault type |
| deployRecoveryServicesVault | true | For VM/file share baselines |
| deployManagedDisk | false | Optional: set to true for disk backup demo |
| deployAKSCluster | false | Optional: set to true for container backup demo |
| deployBlobBackup | false | Optional: set to true for operational backup demo |
| deployWindowsVm | false | Not required for modern workloads pattern |
| deployAzureFiles | false | Not required for modern workloads pattern |
| vaultStorageRedundancy_RSV | LRS | Cost-optimized for dev/test |
| vaultStorageRedundancy_Backup | LRS | Backup vault defaults to LRS |
| retentionDays | 7 | Short retention (focus on vault features, not retention) |

## Architecture

### Vault Separation Model

```
┌──────────────────────────────────────────────────────────────────┐
│ Azure Subscription                                               │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────┐                            │
│  │ RECOVERY SERVICES VAULT         │                            │
│  │ (Traditional Workloads)         │                            │
│  ├─────────────────────────────────┤                            │
│  │ ✓ VMs (IaaS)                    │                            │
│  │ ✓ Azure Files (SMB/NFS)         │                            │
│  │ ✓ SQL Server in VM              │                            │
│  │ ✓ SAP HANA                      │                            │
│  │ ✓ On-Premises Servers           │                            │
│  │                                 │                            │
│  │ Storage:  GRS/LRS Snapshots     │                            │
│  │ Restore:  File, Disk, Full VM   │                            │
│  │ Retention: 1-9999 days          │                            │
│  └─────────────────────────────────┘                            │
│                                                                  │
│  ┌─────────────────────────────────┐                            │
│  │ BACKUP VAULT (New)              │                            │
│  │ (Modern Workloads)              │                            │
│  ├─────────────────────────────────┤                            │
│  │ ✓ Managed Disks (Premium/Std)   │                            │
│  │ ✓ AKS Cluster Backup            │                            │
│  │ ✓ Blob (Operational Restore)    │                            │
│  │ ✓ Azure App Service (preview)   │                            │
│  │                                 │                            │
│  │ Storage:  LRS (immutable)       │                            │
│  │ Restore:  Granular snapshots    │                            │
│  │ Retention: 1-35 days (SLAs)     │                            │
│  └─────────────────────────────────┘                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Workload placement by vault type

| Workload | Vault Type | Why | Restore Strategy |
|---|---|---|---|
| Azure VM (IaaS) | **Recovery Services** | File/disk/full VM restore options | Disk restore or file-level |
| Azure Files (SMB) | **Recovery Services** | Snapshot-based point-in-time restore | Item-level or full share |
| SQL Server in VM | **Recovery Services** | Transaction log backup chain | Application-aware restore |
| SAP HANA | **Recovery Services** | Specialized agent, 5-minute RPO | Database-aware restore |
| **Managed Disk** | **Backup Vault** | Snapshot-based, 35-day max retention | Disk snapshot restore |
| **AKS Cluster** | **Backup Vault** | Etcd + PV backup, cluster state | Cluster-level restore |
| **Blob Storage** | **Backup Vault** | Point-in-time operational restore | Block blob version restore |
| **App Service** | **Backup Vault** | Code + config backup (preview) | Application artifact restore |

## Backup policies by vault/workload

### Recovery Services Vault Policies

**Policy 1: VM Daily Backup (7-day retention)**
```
Name: modern-vm-daily
Frequency: Daily @ 11:00 PM UTC
Retention: 7 days (daily snapshots)
Instant restore snapshots: 5 days
Workload: Windows/Linux VMs
```

### Backup Vault Policies

**Policy 1: Managed Disk Daily (30-day retention)**
```
Name: modern-disk-daily
Frequency: Daily snapshots
Retention: 30 days (Backup vault max varies by disk tier)
Snapshot location: Managed disk region
Workload: Premium SSD/Standard HDD
```

**Policy 2: Blob Operational Backup (7-day retention)**
```
Name: modern-blob-operational
Frequency: Continuous (operational restore)
Retention: 7 days (point-in-time recovery window)
Scope: Entire storage account (block blobs)
Workload: Unstructured data, files, documents
```

**Policy 3: AKS Cluster Backup (Weekly, 4-week retention)**
```
Name: modern-aks-weekly
Frequency: Weekly @ Saturday 02:00 AM UTC
Retention: 4 weeks (4 backups)
Scope: Full cluster state (Etcd + PVs)
Workload: Kubernetes clusters, microservices
Restore: Different cluster or same cluster point-in-time
```

## Demo scenarios

### Scenario 1: Vault selection matrix (5 min)

Present vault comparison table, discuss:
- Why traditional workloads go to RSV (legacy agent support, flexibility)
- Why modern workloads go to Backup vault (cloud-native, integrated)
- Cost implications (disk snapshots cheaper than RSV monthly charge)

**Demo steps**:
1. Show RSV in Azure portal (note storage redundancy options)
2. Show Backup vault in Azure portal (note simplified UI, no redundancy choice)
3. Present decision table by workload

### Scenario 2: Managed disk backup & restore (10 min)

**Demo steps**:
1. Create managed disk (Premium SSD, 64 GB)
2. Enable Backup vault protection
3. Trigger snapshot
4. Show snapshot details
5. Create disk from snapshot
6. Attach to test VM

**Talking points**:
- "Managed disks are cloud-first, so backups are simpler"
- "Snapshots cost less than VHD blobs"
- "Restore is immediate — no restore job overhead"

### Scenario 3: Blob operational backup (5 min)

**Demo steps**:
1. Create storage account with Backup vault protection
2. Upload sample files to blob container
3. Show operational backup UI (enable continuous point-in-time)
4. Delete a file after 2 minutes
5. Restore file to point-in-time (before deletion)
6. Show restored blob in original container

**Talking points**:
- "Blob backup is continuous, no job scheduling needed"
- "Ransomware protection: attacker deletes blobs, you restore instantly"
- "7-day window is shorter than traditional backup (cost trade-off)"

### Scenario 4: AKS cluster backup (optional, 15 min if deployed)

**Demo steps** (if AKS cluster deployed):
1. Deploy sample workload (Nginx, MySQL) to AKS
2. Enable Backup vault cluster backup
3. Trigger full cluster backup (Etcd + PVs)
4. Show backup job progress
5. Demonstrate restore to alternate cluster

**Talking points**:
- "Kubernetes clusters are stateful — backup captures state for disaster recovery"
- "Restore to new cluster for testing/recovery"
- "Backup vault is purpose-built for Kubernetes"

## Monitoring & diagnostics

### KQL Queries (Log Analytics)

**Query 1: Backup Coverage by Vault Type**
```kusto
AzureDiagnostics
| where ResourceType in ("VAULTS", "BACKUPVAULTS")
| where OperationName == "BackupItem"
| summarize count() by tostring(ResourceType), BackupItemType
```

**Query 2: Vault Storage Redundancy & Workloads**
```kusto
AzureDiagnostics
| where ResourceType in ("VAULTS", "BACKUPVAULTS")
| where OperationName == "CreateVault"
| project Vault = ResourceName, StorageRedundancy, BackupWorkloads = Details
```

**Query 3: Restore Time by Workload (SLA tracking)**
```kusto
AzureDiagnostics
| where OperationName == "Restore"
| extend Duration = TimeGenerated - todouble(StartTime)
| summarize AvgDurationMins = avg(Duration) by BackupItemType
| order by AvgDurationMins desc
```

## Definition of done

The demonstration is complete when:

- ✅ Both Recovery Services vault and Backup vault deployed successfully
- ✅ Platform team understands vault placement (RSV for IaaS, Backup vault for cloud-native)
- ✅ At least one workload protected in each vault (e.g., VM in RSV, Disk in Backup vault)
- ✅ Backup job completed and recovery point visible for each vault
- ✅ Managed disk snapshot restore demonstrated (optional: deploy disk)
- ✅ Blob operational backup restore demonstrated (optional: deploy blob storage)
- ✅ Log Analytics queries show vault metrics and workload distribution
- ✅ Presenter explains cost trade-offs (retention vs. vault type) clearly
- ✅ Platform team can articulate when to use each vault for their workloads
- ✅ All resources cleaned up and cost incurred documented

## Presenter talking points

1. **Vault evolution**: RSV is mature (10+ years), Backup vault is cloud-native (2023+)
2. **Cost optimization**: Backup vault cheaper for short-retention cloud-native workloads
3. **Architecture simplicity**: One vault per workload family reduces complexity
4. **Retention flexibility**: RSV allows 1-9999 days, Backup vault enforces SLA-based retention
5. **Cloud landing zone strategy**: Use Backup vault for all new cloud-native projects

## Parameters (for Bicep deployment)

```bicep
param environmentName string = 'backup-modern'
param location string = 'eastus'
param owner string = 'platform-team'
param deployBackupVault bool = true
param deployRecoveryServicesVault bool = true
param deployManagedDisk bool = false
param deployAKSCluster bool = false
param deployBlobBackup bool = false
param vaultStorageRedundancy string = 'LRS'
param retentionDays int = 7
```

## Dependencies & prerequisites

- Azure subscription with both RecoveryServices and DataProtection resource providers registered
- Azure CLI >= 2.45.0 or PowerShell 7+ with Az.RecoveryServices and Az.DataProtection modules
- User with Subscription Contributor role for initial deployment
- Log Analytics workspace for diagnostics

## Success criteria

Pattern C demonstration is successful when:

1. **Clarity**: Platform team can articulate when to use each vault type
2. **Architecture**: Workload placement decisions are driven by vault capabilities, not personal preference
3. **Cost**: Team understands retention/redundancy trade-offs and can optimize spending
4. **Operations**: Log Analytics queries show workload distribution across vault types
5. **Narrative**: Presenter confidently explains cloud-native backup strategy for platform teams
