# Pattern C: Modern Workloads — Infrastructure Deployment Guide

**Version**: 1.0  
**Last Updated**: 2026-06-23  
**Target Audience**: Platform teams, DevOps engineers, cloud architects  
**Deployment Time**: 30-35 minutes

---

## Overview

This guide provides a **spec-driven, single-step deployment** for Pattern C (Modern Workloads). Demonstrates vault differentiation: Recovery Services Vault (traditional IaaS) vs. Backup Vault (cloud-native).

### What Gets Deployed

- **2 Resource Groups**: Workload + Protection
- **1 Recovery Services Vault** (RSV) for VM/file share backup
- **1 Backup Vault** (new tier) for managed disk/blob/AKS
- **1 Windows VM** (optional, for RSV demo)
- **1 Managed Disk** (Premium SSD, optional for Backup vault demo)
- **1 Storage Account** with blob (optional for operational backup)
- **1 Log Analytics Workspace** for workload diagnostics
- **Workload placement matrix** showing vault selection logic

### Architecture Diagram

```
Subscription
├── Recovery Services Vault (RSV)
│   ├── Azure VMs (IaaS)
│   ├── Azure Files (SMB/NFS)
│   ├── SQL Server in VM
│   └── On-premises Servers
│
└── Backup Vault (Cloud-Native)
    ├── Managed Disks (Premium/Standard)
    ├── Azure Blob (Operational Backup)
    ├── AKS Clusters (Optional)
    └── App Services (Preview)
```

---

## Prerequisites

### Required Software
- **Azure CLI** >= 2.50.0 with DataProtection extension
- **PowerShell 7+** with Az.RecoveryServices and Az.DataProtection modules
- **Bicep CLI** (auto-installed with Azure CLI 2.48+)

### Azure Resource Providers
Both providers must be registered:

```bash
# Register DataProtection (for Backup Vault)
az provider register --namespace Microsoft.DataProtection

# Register RecoveryServices (for Recovery Services Vault)
az provider register --namespace Microsoft.RecoveryServices

# Verify (should show "Registered" state)
az provider show --namespace Microsoft.DataProtection --query registrationState
az provider show --namespace Microsoft.RecoveryServices --query registrationState
```

### Azure Quotas
```bash
az vm list-usage --location eastus -o table
# Verify: Compute cores >= 2, Storage accounts >= 1, Managed disks >= 1
```

---

## Deployment Steps

### Step 1: Clone & Navigate to Pattern C

```bash
git clone https://github.com/KrishnaDistributedcomputing/AzureAIDeployments.git
cd AzureAIDeployments/azure-backup-pattern-c-spec/infra
```

### Step 2: Customize Deployment Parameters

Edit `parameters.bicepparam`:

```bicep
using './main.bicep'

param environmentName = 'backup-modern'            // Naming prefix
param location = 'eastus'                          // AKS availability
param owner = 'platform-team'                      // Team tag
param deployBackupVault = true                     // REQUIRED: true
param deployRecoveryServicesVault = true           // VM/file demo
param deployManagedDisk = false                    // Set to true for disk backup demo
param deployAKSCluster = false                     // Set to true for AKS backup demo (20+ min)
param deployBlobBackup = false                     // Set to true for operational backup demo
param deployWindowsVm = false                      // Optional VM for RSV demo
param vaultStorageRedundancy = 'LRS'               // Cost-optimized for demo
param retentionDays = 7                            // Short retention for demo
```

**Demo Profiles** (choose one):

**Profile 1: Vault Comparison** (fastest, 10 min)
```bicep
deployBackupVault = true
deployRecoveryServicesVault = true
deployManagedDisk = false
deployAKSCluster = false
deployBlobBackup = false
```

**Profile 2: Full Cloud-Native** (30 min)
```bicep
deployBackupVault = true
deployRecoveryServicesVault = true
deployManagedDisk = true
deployAKSCluster = false
deployBlobBackup = true
```

**Profile 3: Kubernetes** (40 min, requires AKS capacity)
```bicep
deployBackupVault = true
deployRecoveryServicesVault = false
deployManagedDisk = false
deployAKSCluster = true
deployBlobBackup = false
```

### Step 3: Deploy Using Bicep

```bash
# Option A: Azure CLI
az deployment sub create \
  --name pattern-c-deployment \
  --location eastus \
  --template-file main.bicep \
  --parameters @parameters.bicepparam

# Option B: PowerShell
New-AzSubscriptionDeployment `
  -Name "pattern-c-deployment" `
  -Location "eastus" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.bicepparam"
```

**Deployment Output**:
```json
{
  "recoveryServicesVaultName": "rsv-backup-modern-eastus",
  "backupVaultName": "bkpvault-backup-modern-eastus",
  "workloadRgName": "rg-backup-modern-workload",
  "protectionRgName": "rg-backup-modern-protection"
}
```

### Step 4: Validation Checklist

```bash
# 1. Verify both vaults exist
az backup vault list -g rg-backup-modern-protection --query "[].name"
az dataprotection backup-vault list -g rg-backup-modern-protection --query "[].name"

# 2. Verify storage redundancy
az backup vault show \
  -g rg-backup-modern-protection \
  -n rsv-backup-modern-eastus \
  --query "properties.storageModelType"

# 3. Verify Log Analytics workspace connected
az monitor diagnostic-settings list \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourcegroups/rg-backup-modern-protection/providers/microsoft.recoveryservices/vaults/rsv-backup-modern-eastus"

# 4. If managed disk deployed, verify it exists
az disk list -g rg-backup-modern-workload --query "[].name"

# 5. If blob storage deployed, verify it exists
az storage account list -g rg-backup-modern-workload --query "[].name"
```

---

## Demo Scenarios (Use After Deployment)

### Scenario 1: Vault Comparison Matrix (5 minutes)

**Objective**: Show when to use each vault type

**Demo Steps**:

```bash
# 1. Show Recovery Services Vault (traditional)
az backup vault show \
  -g rg-backup-modern-protection \
  -n rsv-backup-modern-eastus \
  --query "properties.{storageType: storageModelType, backupStorageVersion: backupStorageVersion}"

# 2. Show Backup Vault (cloud-native)
az dataprotection backup-vault show \
  -g rg-backup-modern-protection \
  -n bkpvault-backup-modern-eastus \
  --query "properties.{storageSettings: storageSettings}"

# 3. Display workload placement matrix (from SPEC.md)
echo "
┌───────────────────────┬──────────────────┬──────────────────────┐
│ Workload              │ Vault Type       │ Restore Strategy     │
├───────────────────────┼──────────────────┼──────────────────────┤
│ Azure VM (IaaS)       │ RSV              │ File/Disk/Full VM    │
│ Azure Files (SMB)     │ RSV              │ Item-level/Full share│
│ SQL Server in VM      │ RSV              │ DB-aware restore     │
│ Managed Disk          │ Backup Vault     │ Disk snapshot        │
│ Azure Blob            │ Backup Vault     │ Point-in-time        │
│ AKS Cluster           │ Backup Vault     │ Cluster-level        │
│ App Service (preview) │ Backup Vault     │ Code + config        │
└───────────────────────┴──────────────────┴──────────────────────┘
"
```

**Talking Points**:
- "RSV is mature, flexible, supports legacy workloads"
- "Backup Vault is cloud-native, simpler, SLA-driven retention"
- "Disk snapshots are cheaper than RSV monthly charges"
- "Choose vault type based on workload, not preference"

### Scenario 2: Managed Disk Backup & Restore (10 minutes)

*Only if `deployManagedDisk = true`*

```bash
# 1. List managed disk and backup configuration
az disk list -g rg-backup-modern-workload --query "[].{name:name, tier:sku.tier}"

# 2. Enable backup for managed disk
DISK_ID=$(az disk list -g rg-backup-modern-workload -n managed-disk-backup-modern --query "[0].id" -o tsv)

az dataprotection backup-policy create \
  --policy-name "disk-backup-daily" \
  --datasource-type AzureDisk \
  --backup-vault-name bkpvault-backup-modern-eastus \
  -g rg-backup-modern-protection

# 3. Create backup configuration
az dataprotection backup-instance create \
  --datasource-id $DISK_ID \
  --datasource-type AzureDisk \
  --backup-vault-name bkpvault-backup-modern-eastus \
  -g rg-backup-modern-protection \
  --backup-policy-name "disk-backup-daily"

# 4. Run initial backup
az dataprotection backup-instance restore trigger \
  --backup-instance-name disk-backup-instance \
  --resource-group rg-backup-modern-protection \
  --restore-configuration restore-config.json

# 5. List snapshots created by backup
az snapshot list -g rg-backup-modern-protection --query "[].{name:name, createTime:timeCreated, size:diskSizeGb}"

# 6. Restore from snapshot (create disk)
SNAPSHOT=$(az snapshot list -g rg-backup-modern-protection --query "[0].id" -o tsv)

az disk create \
  --name restored-disk \
  -g rg-backup-modern-workload \
  --source $SNAPSHOT
```

**Talking Points**:
- "Managed disk backup creates snapshots instantly"
- "Restore is faster than recovery from RSV"
- "Snapshots are immutable and geo-replicated"

### Scenario 3: Blob Operational Backup (8 minutes)

*Only if `deployBlobBackup = true`*

```bash
# 1. List storage account
STORAGE_ACCT=$(az storage account list -g rg-backup-modern-workload --query "[0].name" -o tsv)

# 2. Enable operational backup for blobs
az dataprotection backup-policy create \
  --policy-name "blob-operational-daily" \
  --datasource-type AzureBlob \
  --backup-vault-name bkpvault-backup-modern-eastus \
  -g rg-backup-modern-protection \
  --retention-duration P7D  # 7-day retention

# 3. Upload test files to blob
az storage blob upload \
  --account-name $STORAGE_ACCT \
  --container-name backup-demo \
  --name "file-$(date +%s).txt" \
  --file test-file.txt

# 4. Delete a file (simulate accidental deletion)
az storage blob delete \
  --account-name $STORAGE_ACCT \
  --container-name backup-demo \
  --name "file-*.txt"

# 5. Restore deleted blob to point-in-time (before deletion)
az dataprotection backup-instance restore trigger \
  --backup-vault-name bkpvault-backup-modern-eastus \
  -g rg-backup-modern-protection \
  --restore-config "restore-blob-config.json" \
  --restore-id $(date -u -d "1 hour ago" +%Y-%m-%dT%H:%M:%SZ)

# 6. Verify restored blob
az storage blob list \
  --account-name $STORAGE_ACCT \
  --container-name backup-demo \
  --query "[].name"
```

**Talking Points**:
- "Blob backup is continuous, no job scheduling"
- "7-day point-in-time window (shorter, cheaper than RSV)"
- "Ransomware protection: attacker deletes blobs, you restore instantly"

---

## Validation: Pre-Demo Checklist

| Item | Command | Expected |
|------|---------|----------|
| RSV deployed | `az backup vault list ...` | 1 vault |
| Backup Vault deployed | `az dataprotection backup-vault list ...` | 1 vault |
| Log Analytics connected | `az monitor diagnostic-settings list ...` | "Enabled": true |
| Managed disk (optional) | `az disk list -g workload-rg` | 1 disk present |
| Blob storage (optional) | `az storage account list -g workload-rg` | 1 account present |
| Backup policies created | `az backup policy list ...` | ≥ 1 policy |
| No errors in last 24h | Log Analytics query: "Backup Failures 24h" | 0 failed jobs |

---

## Cleanup

```bash
# Delete resource groups
az group delete --name rg-backup-modern-workload --yes --no-wait
az group delete --name rg-backup-modern-protection --yes --no-wait
```

**Estimated Cost**: $30-50/day (varies by deployed resources)

---

## Troubleshooting

### Issue: "DataProtection provider not registered"

```bash
az provider register --namespace Microsoft.DataProtection
az provider show --namespace Microsoft.DataProtection --query registrationState
# Wait 2-3 minutes for status to show "Registered"
```

### Issue: "AKS cluster deployment timed out"

```bash
# Reduce node count or remove AKS from deployment
param deployAKSCluster = false
```

### Issue: "Insufficient quota for Compute cores"

```bash
# Request quota increase: Azure Portal → Subscriptions → Usage + Quotas → Request increase
# Or use smaller VM SKU
param vmSku = 'Standard_B2s'  # Instead of Standard_D2s_v3
```

---

## Next Steps

1. **Create Backup Policies**: Configure policies for each workload type
2. **Test Restore Workflows**: Practice file, disk, and blob restores
3. **Document Placement Rules**: Create runbook for workload-to-vault mapping
4. **Implement Cost Tracking**: Query Log Analytics for per-workload costs

---

## Support

- **Issues**: https://github.com/KrishnaDistributedcomputing/AzureAIDeployments/issues
- **Documentation**: See SPEC.md for architecture details and workload matrix
- **Azure Support**: Open case for regional limitations or quota increases

**Last Updated**: 2026-06-23
