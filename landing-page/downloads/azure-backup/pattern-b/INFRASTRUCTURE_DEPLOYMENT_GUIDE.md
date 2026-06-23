# Pattern B: Ransomware Resilience — Infrastructure Deployment Guide

**Version**: 1.0  
**Last Updated**: 2026-06-23  
**Target Audience**: Security architects, backup administrators, infrastructure teams  
**Deployment Time**: 25-30 minutes

---

## Overview

This guide provides a **spec-driven, single-step deployment** for Pattern B (Ransomware Resilience). All infrastructure is defined in Bicep templates and deployed via Azure CLI or PowerShell.

### What Gets Deployed

- **2 Resource Groups**: Workload (VMs, storage) + Protection (vaults, monitoring)
- **1 Recovery Services Vault** with soft delete (14-day) + immutable lock
- **1 Windows VM** with encrypted OS and data disks
- **1 Azure Storage Account** with file share
- **1 Log Analytics Workspace** for audit logging
- **4 RBAC Roles** (Backup Operator, Admin, Restore Operator, Audit Reader)
- **3 Azure Monitor Alert Rules** (backup failures, soft delete, unauthorized restore)
- **Pre-staged recovery point** for demonstration

### Architecture

```
┌─────────────────────────────────┐
│  Workload RG                    │
│  ├─ Windows VM (encrypted)      │
│  │  ├─ OS Disk                  │
│  │  └─ Data Disk (D:)           │
│  └─ Storage Account (Azure Files)
└─────────────────────────────────┘
         ↓ (Backup Agent)
┌─────────────────────────────────┐
│  Protection RG                  │
│  ├─ Recovery Services Vault     │
│  │  ├─ Soft Delete: 14 days     │
│  │  └─ Immutable Lock: ON       │
│  ├─ Log Analytics Workspace     │
│  └─ Azure Monitor Alerts        │
└─────────────────────────────────┘
```

---

## Prerequisites

### Required Software
- **Azure CLI** >= 2.50.0 or **PowerShell 7+** with Az modules
- **Git** for cloning the repository
- **Bicep CLI** (auto-installed with Azure CLI 2.48+)

### Required Permissions
- **Subscription Contributor** role (or custom role with permissions to create RGs, vaults, VMs, RBAC assignments)
- **Directory Administrator** role (for RBAC group assignments)

### Azure Quotas to Verify
```bash
# Check resource quotas in your subscription
az vm list-usage --location canadacentral -o table

# Verify: VM cores >= 4, Storage accounts >= 1, Recovery Services vaults >= 1
```

### Optional: Create Azure AD Security Groups (for RBAC)
```bash
# Create groups for role assignments (optional if using service principals)
az ad group create --display-name "Backup-Operators" --mail-nickname "backup-ops"
az ad group create --display-name "Backup-Admins" --mail-nickname "backup-admins"
az ad group create --display-name "Restore-Operators" --mail-nickname "restore-ops"
az ad group create --display-name "Audit-Readers" --mail-nickname "audit-readers"

# Get object IDs for use in Bicep parameters
az ad group list --filter "displayName eq 'Backup-Operators'" --query "[0].id"
```

---

## Deployment Steps

### Step 1: Clone Repository & Navigate to Pattern B

```bash
git clone https://github.com/KrishnaDistributedcomputing/AzureAIDeployments.git
cd AzureAIDeployments/azure-backup-pattern-b-spec/infra
```

### Step 2: Review Bicep Templates

Verify the following files exist:
- `main.bicep` — Orchestration template
- `parameters.bicepparam` — Default configuration
- `modules/vault.bicep` — Recovery Services Vault with soft delete + immutable lock
- `modules/vm.bicep` — Windows VM with encryption
- `modules/storage.bicep` — Storage account + file share
- `modules/monitoring.bicep` — Log Analytics + alerts
- `modules/rbac.bicep` — RBAC role assignments

### Step 3: Customize Parameters (Optional)

Edit `parameters.bicepparam` to customize:

```bicep
using './main.bicep'

param environmentName = 'backup-resilience'        // Naming prefix
param location = 'canadacentral'                   // Azure region
param owner = 'security-team'                      // Owner tag
param vmAdminUsername = 'azureuser'                // VM login (non-admin)
param softDeleteRetentionDays = 14                 // Ransomware recovery window
param enableSoftDelete = true                      // REQUIRED: true
param enableImmutableVault = true                  // REQUIRED: true
param alertEmail = 'security-team@company.com'     // Alert recipient
```

**Key Security Settings** (DO NOT DISABLE):
- `enableSoftDelete = true` — Prevents ransomware permanent deletion
- `enableImmutableVault = true` — Permanent deletion lock
- VM disks use Azure Disk Encryption (ADE)
- Backup job password stored in Key Vault

### Step 4: Deploy Using Bicep

**Option A: Azure CLI (Recommended)**

```bash
# Deploy to new resource groups
az deployment sub create \
  --name pattern-b-deployment \
  --location canadacentral \
  --template-file main.bicep \
  --parameters @parameters.bicepparam

# Output: Resource group IDs, vault name, VM details
```

**Option B: PowerShell**

```powershell
New-AzSubscriptionDeployment `
  -Name "pattern-b-deployment" `
  -Location "canadacentral" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.bicepparam"
```

**Deployment Output** (save for reference):
```json
{
  "workloadRgName": "rg-backup-resilience-workload",
  "protectionRgName": "rg-backup-resilience-protection",
  "vaultName": "rsv-backup-resilience-cc",
  "vmName": "vm-backup-resilience-prod",
  "logAnalyticsId": "/subscriptions/.../providers/microsoft.operationalinsights/workspaces/law-backup-resilience"
}
```

### Step 5: Validate Deployment (5 minutes)

Run validation checklist:

```bash
# 1. Verify resource groups exist
az group list --query "[?tags.owner=='security-team'].{name:name, rg:name}"

# 2. Verify Recovery Services Vault
az backup vault list -g rg-backup-resilience-protection

# 3. Verify soft delete is enabled
az backup vault backup-properties show \
  -g rg-backup-resilience-protection \
  -n rsv-backup-resilience-cc \
  | grep -i softdelete

# 4. Verify immutable vault lock
az backup vault get \
  -g rg-backup-resilience-protection \
  -n rsv-backup-resilience-cc \
  | grep -i immutable

# 5. Verify RBAC assignments (should see 4 role assignments)
az role assignment list \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query "[?contains(roleDefinitionName, 'Backup')].{role:roleDefinitionName, principal:principalName}" \
  -o table

# 6. Verify VM is online
az vm get-instance-view \
  -g rg-backup-resilience-workload \
  -n vm-backup-resilience-prod \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus"
```

**Success Criteria**:
- ✅ Both resource groups created with correct tags
- ✅ Vault shows: Soft Delete = Enabled, Immutable Lock = Active
- ✅ 4 RBAC roles visible in role assignments
- ✅ VM status = "PowerState/running"
- ✅ Log Analytics workspace receiving diagnostics

### Step 6: Configure Backup Policies

Backup policies are NOT auto-created; configure manually for demo:

```bash
# Create VM daily backup policy (7-day retention)
az backup protection policy create \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection \
  --policy-name resilience-vm-daily \
  --backup-management-type AzureIaaSVM \
  --policy-type AzureIaaSVMPolicy \
  --retention-count 7 \
  --retention-policy-type Daily

# Register VM with vault
az backup protection enable-for-vm \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection \
  --vm vm-backup-resilience-prod \
  --policy-name resilience-vm-daily
```

---

## Verification: Pre-Deployment Checklist

Before running demo, verify all 10 items:

| # | Item | Command | Expected Result |
|---|------|---------|-----------------|
| 1 | Soft Delete Enabled | `az backup vault backup-properties show ...` | "softDeleteFeatureState": "Enabled" |
| 2 | Immutable Lock Active | `az backup vault get ... \| grep immutable` | "locked": true |
| 3 | RBAC Roles Assigned | `az role assignment list ...` | 4 role assignments visible |
| 4 | VM Running | `az vm get-instance-view ... --query powerState` | "PowerState/running" |
| 5 | Backup Policy Active | `az backup protection show ...` | "Status": "Protected" |
| 6 | Alert Rules Created | `az monitor metrics alert list -g protection-rg` | 3 alert rules for backup failures |
| 7 | Log Analytics Connected | Vault → Diagnostic Settings | "Enabled": true for all categories |
| 8 | File Share Accessible | Connect to VM, access \\\\storageaccount\\backup-share | File share mounted successfully |
| 9 | Recovery Point Visible | `az backup recoverypoint list --container-name vm-name --vault-name vault-name` | At least 1 recovery point |
| 10 | No Backup Errors | Log Analytics: Run "Backup Failures 24h" query | 0 failed jobs in last 24h |

---

## Demo Scenarios (Use After Deployment)

### Scenario 1: Role-Based Access Control (RBAC Separation)

**Objective**: Show that RBAC prevents unauthorized backup modifications

```bash
# 1. Demonstrate: Backup Operator CAN trigger restore but NOT modify policy
az backup protection update-for-vm \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection \
  --container-name vm-backup-resilience-prod \
  --item-name vm-backup-resilience-prod \
  --policy-name resilience-vm-daily \
  --as-user "backup-operator@company.com"
# Expected: Permission denied (Backup Operator lacks Update permissions)

# 2. Demonstrate: Backup Administrator CAN modify policy
az backup protection update-for-vm \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection \
  --container-name vm-backup-resilience-prod \
  --item-name vm-backup-resilience-prod \
  --policy-name resilience-vm-daily \
  --as-user "backup-admin@company.com"
# Expected: Policy updated successfully
```

**Presenter Note**: "The backup operator who triggers daily backups cannot disable protections. This prevents ransomware from disabling backups after VM compromise."

### Scenario 2: Soft Delete Recovery (Ransomware Simulation)

**Objective**: Show 14-day recovery window for "deleted" backups

```bash
# 1. Get a recovery point ID
RECOVERY_POINT=$(az backup recoverypoint list \
  --container-name vm-backup-resilience-prod \
  --item-name vm-backup-resilience-prod \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection \
  --query "[0].id" -o tsv)

# 2. "Delete" the recovery point (soft delete, not permanent)
az backup recoverypoint delete \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection \
  --container-name vm-backup-resilience-prod \
  --item-name vm-backup-resilience-prod \
  --backup-management-type AzureIaaSVM \
  --recovery-point-id $RECOVERY_POINT

# 3. Show the point is in soft-delete state (14-day window)
az backup recoverypoint list \
  --container-name vm-backup-resilience-prod \
  --item-name vm-backup-resilience-prod \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection \
  --query "[].{name:name, state:state, deleteState:deleteState}"

# 4. Restore from soft-deleted point
az backup restore submit-for-recovery \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection \
  --recovery-config recovery-config.json

# 5. Run Log Analytics query to show undelete in audit trail
az monitor log-analytics query \
  --workspace $(az resource show -g rg-backup-resilience-protection -n law-backup-resilience --resource-type Microsoft.OperationalInsights/workspaces --query id -o tsv) \
  --analytics-query "AzureDiagnostics | where OperationName == 'UndeleteRecoveryPoint' | project TimeGenerated, Caller, Details"
```

**Presenter Note**: "Even if a ransomware attacker deletes our backups, we have 14 days to recover them. This is enabled by soft delete and protected by immutable vault lock."

### Scenario 3: Monitoring & Alerting

**Objective**: Show real-time security alerts

```bash
# 1. Check alert rules
az monitor metrics alert list \
  -g rg-backup-resilience-protection \
  --query "[].{name:name, condition:criteria.allOf[0].metricName, enabled:enabled}"

# 2. Manually trigger alert (fail a backup job for testing)
# Simulate failure by stopping VM backup agent
az vm run-command invoke \
  -g rg-backup-resilience-workload \
  -n vm-backup-resilience-prod \
  --command-id RunPowerShellScript \
  --scripts "Stop-Service -Name 'Microsoft Azure Recovery Services Agent' -Force"

# 3. View triggered alerts
az monitor alert list --subscription $(az account show --query id -o tsv) --query "[?contains(name, 'backup')]"

# 4. Restore normal operation
az vm run-command invoke \
  -g rg-backup-resilience-workload \
  -n vm-backup-resilience-prod \
  --command-id RunPowerShellScript \
  --scripts "Start-Service -Name 'Microsoft Azure Recovery Services Agent'"
```

---

## Cleanup (Cost Optimization)

After demo, delete resource groups to stop incurring costs:

```bash
# Delete resource groups (vaults + VMs + storage)
az group delete \
  --name rg-backup-resilience-workload \
  --yes --no-wait

az group delete \
  --name rg-backup-resilience-protection \
  --yes --no-wait

# Verify deletion (should return empty after ~2 min)
az group list --query "[?contains(name, 'resilience')]"
```

**Estimated Cost**: $45-60 per day (VM $1.25/day + vault $0.10/day + storage $0.184/day + analytics $0.005/day)

---

## Troubleshooting

### Issue: "Deployment failed: Soft delete is not available in this region"

**Solution**: Change location to supported region (canadacentral, eastus, westeurope, southeastasia)

```bash
# Update parameters.bicepparam
param location = 'eastus'  # Change from canadacentral

# Redeploy
az deployment sub create --name pattern-b-v2 --location eastus --template-file main.bicep --parameters @parameters.bicepparam
```

### Issue: "RBAC role assignment failed: Principal not found"

**Solution**: Verify Azure AD group exists and get correct object ID

```bash
# List all security groups
az ad group list --query "[?contains(displayName, 'Backup')].{name:displayName, id:id}"

# Update parameters.bicepparam with correct object ID
param backupOperatorGroupId = "<object-id-from-above>"
```

### Issue: "Vault deletion is locked (immutable lock active)"

**This is expected behavior** — immutable lock prevents deletion. To remove vault:

```bash
# 1. Disable immutable lock (requires Manual Contributor with "Undelete Backup Vault" permission)
az rest --method PATCH \
  --url "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-backup-resilience-protection/providers/Microsoft.RecoveryServices/vaults/rsv-backup-resilience-cc?api-version=2021-06-01" \
  --body '{"properties":{"securitySettings":{"immutabilitySettings":{"state":"Unlocked"}}}}'

# 2. Delete vault
az backup vault delete \
  --vault-name rsv-backup-resilience-cc \
  --resource-group rg-backup-resilience-protection
```

---

## Next Steps

After successful Pattern B deployment:

1. **Configure Production Workloads**: Enroll actual production VMs in backup policies
2. **Integrate with SIEM**: Send Log Analytics data to Azure Sentinel or Splunk
3. **Set Up Restore Testing**: Monthly restore drills to validate RTO/RPO
4. **Document Runbooks**: Extend 4 operational runbooks (deployment, management, incident response, decommissioning)

---

## Support & Escalation

- **Deployment Issues**: File issue in GitHub: https://github.com/KrishnaDistributedcomputing/AzureAIDeployments/issues
- **Azure Support**: Open Azure Support case for quota increases or regional limitations
- **Backup Team**: Contact backup-team@company.com for policy customization or RBAC changes

**Last Updated**: 2026-06-23
