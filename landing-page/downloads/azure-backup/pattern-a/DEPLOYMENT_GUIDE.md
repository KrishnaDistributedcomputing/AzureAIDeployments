# Pattern A: Core Demo Environment — Spec-Driven Deployment Package

**Version**: 1.0  
**Last Updated**: 2026-06-23  
**Status**: Production-Ready Demo  
**Target Duration**: 30-45 minutes  
**Target Audience**: Sales engineers, customer engineers, solution architects

---

## Executive Summary

**Pattern A** is a rapid-deployment backup demonstration designed for sales and customer engineering teams. It deploys a complete Azure Backup environment in under 1 hour, demonstrating core backup concepts: job scheduling, restore workflows, policy management, and cost efficiency.

**Use Case**: "How do I backup a Windows VM and restore files quickly?"

**Key Message**: Azure Backup protects your VMs and file shares with simple policies, fast restores, and transparent costs.

---

## Deployment Architecture

### High-Level Flow

```
Customer VM (Production Workload)
  └─ Backup Agent
      ├─ Daily backup job @ 11:00 PM UTC
      ├─ 7-day retention (rolling snapshots)
      └─ Creates recovery points

Recovery Services Vault (Backup Storage)
  ├─ Stores backup copies (LRS replication)
  ├─ Policy: Daily @ 11 PM, 7-day retention
  ├─ Diagnostics → Log Analytics
  └─ Soft delete enabled (14-day undelete window)

Restore Paths (Demo Options)
  ├─ File-level restore (fastest, 5 min)
  ├─ Full disk restore (complete recovery, 10 min)
  └─ Full VM restore (catastrophic recovery, 15 min)

Operations & Monitoring
  ├─ Log Analytics workspace (diagnostics, alerting)
  ├─ Azure Monitor dashboard (backup status, cost)
  └─ Alerts for job failures, restore completions
```

---

## Service Descriptions & Tags

### 1. Recovery Services Vault
**What it is**: Central backup storage and policy management service

**Primary Functions**:
- Stores encrypted backup copies of VMs and file shares
- Manages retention policies (how long to keep backups)
- Encrypts all data in transit and at rest
- Provides disaster recovery orchestration

**Demo Tag**: `backup-storage-core`

**Configuration for Pattern A**:
- **Storage Redundancy**: LRS (Local Redundant Storage) — cost-optimized for demo
- **Soft Delete**: Enabled (14-day recovery window for deleted items)
- **Encryption**: AES-256 encryption, managed by Azure
- **Replication**: All backups replicated within single region

**Cost Impact**: $0.30/GB/month (LRS) or $0.39/GB/month (GRS)

**Why This Pattern**: 
- Single vault simplifies architecture
- LRS reduces cost for non-critical demo
- Soft delete demonstrates protection against accidental deletion

---

### 2. Backup Policy (Daily, 7-Day Retention)
**What it is**: Automated schedule that triggers backups and manages retention

**Demo Tag**: `backup-schedule-demo`

**Configuration**:
```
Name: demo-daily-policy
Frequency: Daily @ 11:00 PM UTC
Retention: 7 days (daily snapshots kept)
Instant restore snapshots: 5 days (restore without recovery time)
Soft delete: Enabled (14-day item recovery)
```

**Demo Scenario**:
- Day 1: Backup triggered, recovery point created
- Day 2-7: Rolling daily backups (oldest backup deleted after 7 days)
- Day 8+: Oldest backup permanently deleted

**Why This Pattern**:
- 7-day retention is common for non-critical workloads
- Daily frequency matches typical business requirements
- Instant restore snapshots show fast recovery (no waiting)

---

### 3. Azure VM (Windows or Linux)
**What it is**: Virtual machine representing customer's production workload

**Demo Tag**: `workload-vm-protected`

**Configuration**:
```
VM Name: demo-vm-prod
OS: Windows Server 2022 (or Ubuntu 22.04)
Size: Standard_B2s (2 vCPU, 4GB RAM, cost-optimized)
OS Disk: 30 GB (Standard HDD)
Data Disk: 32 GB (represents customer data)
Network: Default VNet, private IP
Public IP: None (Bastion optional)
```

**Demo Content on VM**:
- Sample business documents (Excel, Word, PDF)
- Database backup files
- Application logs
- Total: ~5-10 GB to demonstrate restore

**Why This Pattern**:
- Small VM size (B2s) keeps demo costs low (~$30-50/month)
- Data disk simulates real workload (databases, files)
- Windows Server 2022 most common enterprise OS

---

### 4. Azure Storage Account & File Share
**What it is**: Shared file repository representing team shared drives

**Demo Tag**: `fileshare-protected-sensitive`

**Configuration**:
```
Storage Account Name: demostgacct{random}
Kind: StorageV2 (general purpose)
Replication: LRS (local redundant, demo only)
File Share Name: demo-shared-data
Quota: 100 GB
Access Protocol: SMB 3.0 (Windows file share)
```

**Demo Content in File Share**:
```
demo-shared-data/
├── Finance/
│   ├── Q2-Budget-Proposal.xlsx (1 MB)
│   ├── Cost-Analysis-2026.pdf (2 MB)
│   └── Employee-Salary-List.csv (500 KB)
├── Projects/
│   ├── Project-A-Archive.zip (50 MB)
│   ├── Project-B-Specs.docx (3 MB)
│   └── Project-C-Presentation.pptx (10 MB)
└── Archive/
    ├── Old-Database-Backup.bak (30 MB)
    ├── System-Logs-2025.zip (100 MB)
    └── Compliance-Records-2024.pdf (5 MB)
```

**Backup Policy**:
```
Frequency: Daily snapshots @ 12:30 AM UTC
Retention: 30 days (Azure Files snapshot retention)
Soft delete: Enabled (14-day recovery)
```

**Why This Pattern**:
- File shares are common attack vector (ransomware target)
- Demonstrates file-level restore (most common recovery scenario)
- Shows protection of unstructured data (documents, archives)

---

### 5. Log Analytics Workspace
**What it is**: Central logging and monitoring service for backup operations

**Demo Tag**: `operations-monitoring-soc`

**Configuration**:
```
Workspace Name: demo-la-workspace
Region: East US (or same as vault)
Retention: 30 days (sufficient for demo audit trail)
SKU: Pay-as-you-go
```

**Connected Diagnostics**:
- Recovery Services Vault → all backup events
- Azure Storage Account → all access events
- Azure VM → system performance metrics

**Demo Queries** (ready to run in Log Analytics):

**Query 1: Backup Job Status (Last 24 hours)**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName == "BackupJob"
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationName, Status, BackupItemFriendlyName
| order by TimeGenerated desc
```

**Query 2: Recovery Points Available**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName == "BackupItem"
| where TimeGenerated > ago(7d)
| summarize BackupItemCount = dcount(BackupItemFriendlyName), 
            LatestBackup = max(TimeGenerated) by BackupItemType
```

**Query 3: Restore Operations (Demo Walkthrough)**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName == "Restore"
| project TimeGenerated, RestorePath = parse_json(Details)["RestoreType"], Status, Duration
```

**Why This Pattern**:
- Centralized audit trail for compliance
- Real-time visibility into backup jobs
- Cost tracking (can estimate monthly bill)
- Alert setup demonstration

---

### 6. Azure Monitor Alerts & Action Groups
**What it is**: Automated notifications for backup events

**Demo Tag**: `notifications-incidents-ops`

**Alert Rules**:

**Alert 1: Backup Job Failure**
```
Condition: Any backup job fails
Severity: High
Action: Email notification + optional Teams webhook
Message: "Backup job failed for {BackupItemName}. Check Recovery Services vault."
```

**Alert 2: Restore Operation Completed**
```
Condition: Restore job completes (success or failure)
Severity: Informational
Action: Email notification
Message: "File restore completed for {BackupItemName}. Check Log Analytics for details."
```

**Alert 3: Soft Delete Item**
```
Condition: Backup item soft-deleted (accidental deletion)
Severity: Medium
Action: Email + incident ticket
Message: "Backup item {BackupItemName} was deleted. Available for undelete for 14 days."
```

**Why This Pattern**:
- Demonstrates proactive monitoring
- Shows cost of alerts (free)
- Builds confidence in backup reliability

---

## Tagging Strategy for Pattern A

### Mandatory Tags
All resources tagged for governance, cost tracking, and organization:

```
Tag: environment
Values: demo, production, staging, development
Usage: Segregates demo resources from production

Tag: backup-policy
Values: daily-7, daily-30, weekly-90
Usage: Indicates backup frequency and retention (demo = daily-7)

Tag: demo-use-case
Values: core-demo, ransomware-resilience, modern-workloads, enterprise-landing-zone
Usage: Identifies which pattern this resource belongs to (demo = core-demo)

Tag: cost-center
Values: IT-Engineering, Sales-Engineering, Customer-Engineering
Usage: Chargeback for demo costs

Tag: owner
Values: demo-team@company.com
Usage: Escalation and support contact
```

### Tag Application Example

```
Resource: demo-vm-prod (Virtual Machine)
Tags:
  environment: demo
  backup-policy: daily-7
  demo-use-case: core-demo
  cost-center: Sales-Engineering
  owner: demo-team@company.com
  data-classification: demo

Resource: demo-vault (Recovery Services Vault)
Tags:
  environment: demo
  backup-policy: daily-7
  demo-use-case: core-demo
  cost-center: Sales-Engineering
  owner: demo-team@company.com
  operations-tier: backup-storage
```

---

## Deployment Steps

### Prerequisites
- Azure subscription with $100+ available credits
- User with Subscription Contributor role
- Azure CLI >= 2.45.0 or PowerShell 7+
- Bicep CLI installed

### Phase 1: Preparation (5 minutes)

```powershell
# 1. Set variables
$resourceGroup = "rg-demo-backup-core-$(Get-Random)"
$location = "eastus"
$vaultName = "demo-vault-$(Get-Random)"
$vmName = "demo-vm-prod"

# 2. Register resource providers
az provider register --namespace Microsoft.RecoveryServices
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.OperationalInsights

# 3. Create resource group
az group create --name $resourceGroup --location $location --tags `
  environment=demo `
  backup-policy=daily-7 `
  demo-use-case=core-demo `
  cost-center=Sales-Engineering `
  owner=demo-team@company.com
```

### Phase 2: Infrastructure Deployment (20 minutes)

```powershell
# 4. Deploy Bicep template (infrastructure)
az deployment group create `
  --name demo-backup-deployment `
  --resource-group $resourceGroup `
  --template-file ./infra/main.bicep `
  --parameters `
    vmName=$vmName `
    vaultName=$vaultName `
    environment=demo `
    backupPolicy=daily-7

# Output: Deploy complete, outputs include:
#   - VM public IP (if assigned)
#   - Vault resource ID
#   - Storage account name
#   - Log Analytics workspace ID
```

### Phase 3: Demo Data Seeding (10 minutes)

```powershell
# 5. Seed demo data on VM
./scripts/seed-demo-data.ps1 -VmName $vmName -ResourceGroup $resourceGroup

# This creates:
#   - C:\DemoData\ directory with sample files (Excel, Word, PDF, archives)
#   - Azure file share with shared documents
#   - Sample database backup files
```

### Phase 4: Backup Job Trigger (2 minutes)

```powershell
# 6. Trigger first backup job (don't wait for 11 PM schedule)
./scripts/trigger-backup.ps1 -VaultName $vaultName -ResourceGroup $resourceGroup

# Waits for backup job to complete (typically 5-10 minutes)
# Output: Recovery point created, ready for restore demo
```

### Phase 5: Demo & Restore Walkthroughs (15 minutes)

```powershell
# 7. Run demo script (guides through restore scenarios)
./scripts/demo-restore-scenarios.ps1 -VaultName $vaultName -ResourceGroup $resourceGroup

# Demonstrates:
#   - File-level restore (download 3 files from backup)
#   - Full disk restore (create managed disk from backup)
#   - Show backup job history in Azure Portal
```

### Phase 6: Cleanup (5 minutes)

```powershell
# 8. Clean up all resources
az group delete --name $resourceGroup --yes --no-wait

# Output: Deletion initiated, completes in background
# Cost saved: Stops all billing for demo resources
```

---

## Demo Scenarios & Talking Points

### Scenario 1: "My VM crashed, how do I restore files?" (5 min)

**Demo Steps**:
1. Show backup job in vault ("Last backup 2 hours ago")
2. Click "Restore" on recovery point
3. Browse and download specific files (Excel, PDF)
4. Show files restored to original VM

**Talking Points**:
- "Recovery points created every day at 11 PM"
- "File-level restore is fastest — no full VM restore overhead"
- "7-day retention means you can restore any day from this week"

**Cost Message**: "$0.30/GB/month for backup storage"

---

### Scenario 2: "A disk crashed, can you replace it?" (8 min)

**Demo Steps**:
1. Show recovery point in vault
2. Click "Restore Disks"
3. Specify target resource group
4. Wait 2-5 minutes for disk creation
5. Show managed disk created from backup
6. Attach disk to test VM

**Talking Points**:
- "Full disk restore creates managed disk within 5 minutes"
- "Works even if entire VM is deleted"
- "Restore to different resource group (test before production)"

**Cost Message**: "Managed disk costs $5-10/month (depending on size)"

---

### Scenario 3: "We need a 30-day retention policy for compliance" (5 min)

**Demo Steps**:
1. Show current policy (daily, 7-day retention)
2. Modify policy to 30 days
3. Show cost impact ($0.30/GB × 30 = $9/GB for 30 days)
4. Explain trade-off (more retention = higher cost)

**Talking Points**:
- "Retention policies are flexible, change anytime"
- "This customer has 500 GB → $150/month (7 days) → $450/month (30 days)"
- "Can optimize by choosing differential policies per workload"

**Cost Message**: "$0.30/GB/month baseline, scales with retention"

---

## Restore Workflows (Demo Scripts)

### Workflow 1: File-Level Restore (Fastest, 5 min)

**Use Case**: "I accidentally deleted important files"

**Steps**:
```
1. Azure Portal → Recovery Services Vault
2. Select backup item (demo-vm-prod)
3. Click "Restore Disks"
4. Select recovery point (choose "2 days ago")
5. Select files to restore (Finance/Budget.xlsx, Projects/Archive.zip)
6. Download restore .iso file
7. Mount .iso on original VM
8. Copy files to C:\ drive
```

**Demo Output**:
- Restore completes in 3-5 minutes
- Files available immediately
- No downtime, no RTO concern

**Talking Point**: "File restore is what 80% of customers use"

---

### Workflow 2: Full Disk Restore (10 min)

**Use Case**: "Disk corruption, restore complete drive"

**Steps**:
```
1. Azure Portal → Recovery Services Vault
2. Select backup item (demo-vm-prod data disk)
3. Click "Restore Disks"
4. Target resource group: demo-test-rg
5. Wait 5 minutes for managed disk creation
6. Attach managed disk to test VM
7. Verify data integrity (files exist, checksums match)
```

**Demo Output**:
- Managed disk created in target RG
- Data fully available in test environment
- Can verify before attaching to production

**Talking Point**: "Full disk restore lets you test before production"

---

### Workflow 3: Full VM Restore (15 min, optional)

**Use Case**: "Entire VM deleted, need full recovery"

**Steps**:
```
1. Azure Portal → Recovery Services Vault
2. Select backup item (demo-vm-prod)
3. Click "Restore" (full VM)
4. Target resource group: demo-restore-rg
5. Wait 10-15 minutes for VM provisioning
6. New VM appears with all data, config, applications
```

**Demo Output**:
- New VM created with same OS, apps, data
- Ready to start or connect immediately
- Original VM untouched (can compare versions)

**Talking Point**: "Full VM restore for disaster recovery scenarios"

---

## Cost Breakdown

### Demo Environment Costs

| Service | Size | Duration | Monthly Cost |
|---------|------|----------|--------------|
| **VM (B2s)** | 2 vCPU, 4 GB | 24 hours | ~$35 |
| **OS Disk (30 GB)** | Standard HDD | 24 hours | ~$1 |
| **Data Disk (32 GB)** | Standard HDD | 24 hours | ~$1 |
| **Storage Account (100 GB)** | LRS | 24 hours | ~$2 |
| **File Share (100 GB)** | - | 24 hours | ~$5 |
| **Recovery Services Vault** | 10 GB backup | 7-day retention | $3 |
| **Log Analytics** | 30-day retention | diagnostic logs | ~$0.50 |
| **Network traffic** | Egress | minimal | ~$0 |
| | | **Total per 24 hours** | **~$47** |

**Cost Optimization Tips**:
- Stop VM after demo (pause compute cost)
- Delete demo resources immediately (avoid overnight billing)
- Use B-series burstable VMs for non-production
- 7-day retention is enough for demo (don't increase)

---

## Success Criteria: Demo Readiness Checklist

Before running demo with customer:

- [ ] VM deployed and accessible (RDP/SSH)
- [ ] Demo data seeded (files on VM and file share)
- [ ] Backup job completed (recovery point visible in vault)
- [ ] Log Analytics receiving diagnostics (queries return data)
- [ ] File-level restore works (can download files)
- [ ] Soft delete explained (can demonstrate delete + undelete)
- [ ] Cost calculated and reviewed (manager approval)
- [ ] Cleanup script tested (can delete all resources)
- [ ] Presenter notes reviewed and practiced
- [ ] Customer questions anticipated and answered

---

## Troubleshooting

### Q: "Backup job failed to start"
**A**: Check VM backup agent status
```powershell
# On VM, run:
Get-Service -Name waagent | Select-Object Status
# Should show: Running
```

### Q: "Can't see recovery points in vault"
**A**: Check vault diagnostics are enabled
```powershell
az monitor diagnostic-settings list `
  --resource /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.RecoveryServices/vaults/{vault}
```

### Q: "Restore job takes too long"
**A**: Use file-level restore instead of full VM restore (faster)

### Q: "Cost is higher than expected"
**A**: Delete demo resources immediately after demo, don't leave running overnight

---

## Files Included in This Package

```
azure-backup-pattern-a-core-demo/
├── DEPLOYMENT_GUIDE.md (this file)
├── SPEC.md (technical specification)
├── README.md (quick-start)
├── infra/
│   ├── main.bicep (infrastructure template)
│   └── modules/
│       ├── vm.bicep
│       ├── storage.bicep
│       ├── recovery-services-vault.bicep
│       ├── log-analytics.bicep
│       └── monitoring.bicep
├── scripts/
│   ├── deploy.ps1 (main deployment script)
│   ├── seed-demo-data.ps1 (populate demo data)
│   ├── trigger-backup.ps1 (start backup job)
│   ├── validate-backup.ps1 (verify deployment)
│   ├── demo-restore-scenarios.ps1 (run demo)
│   ├── cleanup-demo.ps1 (delete all resources)
│   └── cost-calculator.ps1 (estimate demo cost)
├── queries/
│   ├── backup-jobs.kql (job status queries)
│   ├── restore-operations.kql (restore tracking)
│   └── cost-tracking.kql (expense analysis)
└── docs/
    ├── architecture.md
    ├── presenter-notes.md
    ├── customer-talking-points.md
    └── frequently-asked-questions.md
```

---

## Presenter Notes for Sales Demo

**Opening (2 min)**:
"Azure Backup is the enterprise-grade backup solution built into Azure. Today I'll show you how easy it is to protect your VMs and file shares, and how quickly you can recover."

**Demo (25 min)**:
1. Show vault created (2 min)
2. Show VM with data (3 min)
3. Show backup job completed (2 min)
4. File-level restore demo (5 min)
5. Full disk restore demo (8 min)
6. Soft delete explanation (3 min)
7. Cost review (2 min)

**Closing (5 min)**:
"Questions? What backup challenges are you facing today?"

---

## Next Steps After Demo

1. **Discuss production requirements** (retention, redundancy, compliance)
2. **Review cost model** (backup size × retention × redundancy)
3. **Plan implementation** (which VMs/workloads to protect)
4. **Discuss governance** (tagging, cost allocation, RBAC)
5. **Schedule POC** (if not already in this demo)

---

**Document Version**: 1.0  
**Last Updated**: 2026-06-23  
**Status**: Ready for Sales Demo  
**Next Review**: 2026-07-23
