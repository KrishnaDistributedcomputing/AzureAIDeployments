# Pattern D: Enterprise Landing Zone — Infrastructure Deployment Guide

**Version**: 1.0  
**Last Updated**: 2026-06-23  
**Target Audience**: Enterprise architects, cloud governance officers, CAF practitioners, operations teams  
**Deployment Time**: 40-50 minutes

---

## Overview

This guide provides **spec-driven, enterprise-grade deployment** for Pattern D (Enterprise Landing Zone). Demonstrates CAF-aligned governance, zero-trust networking, FinOps cost controls, and operational runbooks.

### What Gets Deployed

- **3 Resource Groups** (CAF-aligned):
  - **Workload RG**: Application infrastructure (VMs, storage, databases)
  - **Protection RG**: Backup infrastructure (vaults, private endpoints, monitoring)
  - **Operations RG**: Monitoring, logging, compliance audit
- **2 Backup Vaults**: Recovery Services Vault (RSV) + Backup Vault
- **Network Security**: Private endpoints, NSGs, Azure Bastion
- **Governance**: Azure Policy for tag enforcement, compliance monitoring
- **Monitoring**: Log Analytics workspace, Azure Monitor alerts, FinOps cost tracking
- **Optional**: Azure Sentinel integration for SIEM
- **RBAC**: 5 roles (Admin, Operator, Restore Operator, Vault Reader, Cost Analyst)

### Architecture

```
Management Groups (Policy)
│
└── Subscription: Production-Backup-001
    │
    ├── Workload RG (Team: App Owners)
    │   ├─ Production VMs
    │   ├─ Databases
    │   └─ Azure Files
    │
    ├── Protection RG (Team: Backup/Security)
    │   ├─ RSV (private endpoint)
    │   ├─ Backup Vault (private endpoint)
    │   ├─ Azure Bastion (admin access)
    │   └─ NSGs (zero-trust)
    │
    └── Operations RG (Team: SOC/FinOps)
        ├─ Log Analytics Workspace
        ├─ Storage Account (audit logs)
        ├─ Azure Monitor (alerts)
        └─ Dashboard (cost tracking)
```

---

## Prerequisites

### Required Software
- **Azure CLI** >= 2.50.0 with DataProtection extension
- **PowerShell 7+** with Az.RecoveryServices, Az.DataProtection, Az.Policy modules
- **Bicep CLI** (auto-installed with Azure CLI 2.48+)
- **jq** (JSON query, optional for parsing outputs)

### Required Permissions
- **Subscription Owner** or custom role with:
  - Create/delete resource groups
  - Create/delete Recovery Services vaults
  - Create/delete private endpoints
  - Create/delete Azure Policy definitions
  - Assign RBAC roles
  - Create Log Analytics workspaces

### Azure Quotas to Verify

```bash
# Check core quotas in each region
az vm list-usage --location canadacentral -o table

# Required minimums:
# - Compute cores: >= 8 (4 per workload VM)
# - Storage accounts: >= 3
# - Recovery Services vaults: >= 2 (RSV + Backup Vault)
# - Private endpoints: >= 4 (2 vaults × 2 regions)
# - Bastion hosts: >= 1
```

### Register Required Resource Providers

```bash
# Register all required providers
az provider register --namespace Microsoft.RecoveryServices
az provider register --namespace Microsoft.DataProtection
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.BastionHost
az provider register --namespace Microsoft.Authorization
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.PolicyInsights

# Verify all are registered (status should be "Registered")
az provider list --query "[?namespace=='Microsoft.RecoveryServices' || namespace=='Microsoft.DataProtection'].{provider:namespace, state:registrationState}"
```

---

## Deployment Steps

### Step 1: Clone & Navigate to Pattern D

```bash
git clone https://github.com/KrishnaDistributedcomputing/AzureAIDeployments.git
cd AzureAIDeployments/azure-backup-pattern-d-spec/infra
```

### Step 2: Customize Deployment Parameters

Edit `parameters.bicepparam`:

```bicep
using './main.bicep'

param environmentName = 'backup-enterprise'           // Naming prefix
param location = 'canadacentral'                      // Primary region
param owner = 'enterprise-platform'                   // Owner tag
param workloadRgName = 'rg-backup-enterprise-workload'
param protectionRgName = 'rg-backup-enterprise-protection'
param operationsRgName = 'rg-backup-enterprise-operations'

// Network Security (Zero-Trust)
param deployPrivateEndpoint = true                    // REQUIRED: true
param deployBastion = true                            // Admin access
param enableServiceEndpoints = true                   // Restrict access

// Vault Configuration
param deployRecoveryServicesVault = true
param deployBackupVault = true
param enableSoftDelete = true                         // REQUIRED: true
param enableImmutableVault = true                     // REQUIRED: true
param softDeleteRetentionDays = 14
param vaultStorageRedundancy = 'GRS'                  // Geo-redundancy

// Governance
param deployAzurePolicy = true                        // Tag enforcement
param deployPrivateLink = true                        // Network isolation
param enableAzureSentinel = false                     // Optional: SIEM

// Tagging (CAF-aligned)
param complianceLevels = ['INTERNAL', 'CONFIDENTIAL', 'RESTRICTED']
param costCenterTag = 'enterprise-backup'
param mandatoryTags = {
  environment: 'production'
  'cost-center': 'IT-001'
  'backup-policy': 'daily-30'
  'compliance-level': 'CONFIDENTIAL'
  owner: 'enterprise-platform'
}
```

**Key Enterprise Settings** (DO NOT DISABLE):
- `enableSoftDelete = true` — Ransomware protection (14-day)
- `enableImmutableVault = true` — Permanent deletion lock
- `deployPrivateEndpoint = true` — No public internet access
- `deployBastion = true` — Admin access without RDP/SSH
- `deployAzurePolicy = true` — Compliance automation

### Step 3: Create Azure AD Groups for RBAC

Optional: Create security groups for role assignments

```bash
# Create groups (if not already existing)
az ad group create --display-name "Enterprise-Backup-Admins" --mail-nickname "backup-admins"
az ad group create --display-name "Enterprise-Backup-Operators" --mail-nickname "backup-ops"
az ad group create --display-name "Enterprise-Restore-Operators" --mail-nickname "restore-ops"
az ad group create --display-name "Enterprise-Vault-Readers" --mail-nickname "vault-readers"
az ad group create --display-name "Enterprise-Cost-Analysts" --mail-nickname "cost-analysts"

# Get group object IDs for RBAC
az ad group list --filter "displayName startswith 'Enterprise-'" --query "[].{name:displayName, id:id}" -o table
```

### Step 4: Deploy Using Bicep

```bash
# Option A: Azure CLI
az deployment sub create \
  --name pattern-d-deployment \
  --location canadacentral \
  --template-file main.bicep \
  --parameters @parameters.bicepparam

# Option B: PowerShell
New-AzSubscriptionDeployment `
  -Name "pattern-d-deployment" `
  -Location "canadacentral" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters.bicepparam"
```

**Deployment Output**:
```json
{
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "workloadRgName": "rg-backup-enterprise-workload",
  "workloadRgId": "/subscriptions/.../resourceGroups/rg-backup-enterprise-workload",
  "protectionRgName": "rg-backup-enterprise-protection",
  "operationsRgName": "rg-backup-enterprise-operations",
  "recoveryServicesVaultName": "rsv-backup-enterprise-cc",
  "backupVaultName": "bkpvault-backup-enterprise-cc",
  "logAnalyticsWorkspaceId": "/subscriptions/.../providers/microsoft.operationalinsights/workspaces/law-backup-enterprise"
}
```

### Step 5: Validation Checklist (10 minutes)

```bash
# 1. Verify all 3 resource groups exist
az group list --query "[?contains(name, 'enterprise')].{name:name, owner:tags.owner, environment:tags.environment}"

# 2. Verify both vaults deployed
az backup vault list -g rg-backup-enterprise-protection --query "[].name"
az dataprotection backup-vault list -g rg-backup-enterprise-protection --query "[].name"

# 3. Verify soft delete + immutable lock enabled
az backup vault backup-properties show \
  -g rg-backup-enterprise-protection \
  -n rsv-backup-enterprise-cc \
  | jq '.softDeleteFeatureState, .properties.immutabilitySettings.state'

# 4. Verify private endpoints (no public IPs)
az network private-endpoint list -g rg-backup-enterprise-protection \
  --query "[].{name:name, serviceConnection:privateLinkServiceConnections[0].name}"

# 5. Verify Bastion deployed
az network bastion list -g rg-backup-enterprise-operations \
  --query "[].{name:name, location:location}"

# 6. Verify RBAC roles assigned (should see 5 role assignments)
az role assignment list \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query "[?contains(roleDefinitionName, 'Backup') || contains(roleDefinitionName, 'Cost')].{role:roleDefinitionName, principal:principalName}" \
  -o table

# 7. Verify Azure Policy definitions created
az policy definition list -g rg-backup-enterprise-protection \
  --query "[?contains(name, 'tag')].{name:name, displayName:displayName}"

# 8. Verify Log Analytics workspace connected
WORKSPACE_ID=$(az resource show \
  -g rg-backup-enterprise-operations \
  -n law-backup-enterprise \
  --resource-type Microsoft.OperationalInsights/workspaces \
  --query id -o tsv)

az monitor diagnostic-settings list --resource $WORKSPACE_ID \
  --query "[?properties.logs[0].enabled].{name:name, enabled:properties.enabled}"

# 9. Verify mandatory tags enforced
az policy assignment list \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query "[?contains(displayName, 'require-tagging')].{name:displayName, enforcementMode:properties.enforcementMode}"

# 10. Verify storage account for audit logs
az storage account list -g rg-backup-enterprise-operations \
  --query "[?tags.purpose=='audit-logs'].{name:name, redundancy:sku.name}"
```

**Success Criteria** (all 10 should show positive results):
- ✅ 3 resource groups with correct tags
- ✅ RSV + Backup Vault deployed
- ✅ Soft delete enabled, immutable lock active
- ✅ Private endpoints created (0 public IPs)
- ✅ Bastion host deployed
- ✅ 5 RBAC roles assigned
- ✅ Azure Policy definitions active
- ✅ Log Analytics receiving diagnostics
- ✅ Mandatory tags enforced
- ✅ Audit storage account created

### Step 6: Post-Deployment Configuration

**Configure Azure Sentinel (Optional)**

```bash
# Enable Sentinel on Log Analytics workspace
WORKSPACE_ID=$(az resource show \
  -g rg-backup-enterprise-operations \
  -n law-backup-enterprise \
  --resource-type Microsoft.OperationalInsights/workspaces \
  --query id -o tsv)

az sentinel onboard --resource-group rg-backup-enterprise-operations --workspace-name law-backup-enterprise
```

**Import KQL Queries into Log Analytics**

```bash
# Upload all 4 KQL queries to saved searches
for query in ../queries/*.kql; do
  az monitor log-analytics workspace saved-search create \
    --workspace-name law-backup-enterprise \
    --resource-group rg-backup-enterprise-operations \
    --name "$(basename $query .kql)" \
    --category "Backup" \
    --display-name "$(basename $query .kql)" \
    --saved-query "$(cat $query)"
done
```

---

## Demo Scenarios (Use After Deployment)

### Scenario 1: CAF Governance Model (10 minutes)

**Objective**: Show three-tier resource separation and tag-driven governance

```bash
# 1. Show resource group ownership
echo "=== Resource Group Separation (CAF Model) ==="
az group list -g rg-backup-enterprise* --query "[].{name:name, owner:tags.owner, purpose:tags['rg-function']}"

# 2. Show mandatory tags enforced
echo "=== Mandatory Tags (Azure Policy) ==="
az group show -n rg-backup-enterprise-workload --query tags

# 3. Show cost center allocation
echo "=== Cost Center Tags ==="
az resource list -g rg-backup-enterprise-workload \
  --query "[].{name:name, costCenter:tags['cost-center'], owner:tags.owner}"

# 4. Run Log Analytics query for cost tracking
echo "=== Cost Tracking by Cost Center (Last 24h) ==="
az monitor log-analytics query \
  --workspace $(az resource show -g rg-backup-enterprise-operations -n law-backup-enterprise --resource-type Microsoft.OperationalInsights/workspaces --query id -o tsv) \
  --analytics-query "@$(cat ../queries/cost-by-cost-center.kql)"
```

**Talking Points**:
- "Three-tier separation: Workload team owns VMs, Backup team owns vaults, SOC team owns monitoring"
- "Tags drive backup policies, retention, and cost allocation"
- "Azure Policy prevents tag deletion, ensuring compliance"

### Scenario 2: Zero-Trust Network & Bastion (8 minutes)

**Objective**: Show private endpoint access and RDP/SSH without public IPs

```bash
# 1. Show private endpoints (vaults not on public internet)
echo "=== Private Endpoints (Zero-Trust) ==="
az network private-endpoint list -g rg-backup-enterprise-protection \
  --query "[].{name:name, vault:privateLinkServiceConnections[0].name, status:privateLinkServiceConnections[0].provisioning State}"

# 2. Show Bastion (admin access without RDP/SSH exposure)
echo "=== Bastion Host (Admin Access) ==="
az network bastion list -g rg-backup-enterprise-operations \
  --query "[].{name:name, location:location, tier:sku.name}"

# 3. Connect to VM via Bastion (without RDP/SSH)
BASTION_NAME=$(az network bastion list -g rg-backup-enterprise-operations --query "[0].name" -o tsv)
VM_NAME=$(az vm list -g rg-backup-enterprise-workload --query "[0].name" -o tsv)

echo "To connect to $VM_NAME via Bastion:"
echo "  1. Azure Portal → Bastion → $BASTION_NAME"
echo "  2. Connect to VM → RDP"
echo "  3. No public IP needed (zero-trust)"

# 4. Verify NSGs restrict backup traffic to private endpoints
echo "=== Network Security Groups ==="
az network nsg list -g rg-backup-enterprise-protection \
  --query "[].{name:name, rules:securityRules | length(@)}"
```

**Talking Points**:
- "Backup vault has no public IP — all traffic via private endpoint"
- "Bastion provides secure admin access without RDP/SSH on public internet"
- "NSGs enforce zero-trust: only trusted networks can access backup resources"

### Scenario 3: FinOps & Budget Alerts (8 minutes)

**Objective**: Show cost tracking and budget controls

```bash
# 1. Run cost tracking query
echo "=== Daily Backup Cost by Cost Center ==="
az monitor log-analytics query \
  --workspace $(az resource show -g rg-backup-enterprise-operations -n law-backup-enterprise --resource-type Microsoft.OperationalInsights/workspaces --query id -o tsv) \
  --analytics-query "@$(cat ../queries/cost-by-cost-center.kql)"

# 2. Show Azure Monitor budget alert
az monitor alert list \
  -g rg-backup-enterprise-operations \
  --query "[?contains(name, 'budget')].{name:name, condition:criteria.allOf[0].threshold}"

# 3. Estimate monthly cost
echo "=== Monthly Cost Estimate ==="
PROTECTED_GB=$(az backup item list --vault-name rsv-backup-enterprise-cc -g rg-backup-enterprise-protection --query "length(@)")
MONTHLY_COST=$((PROTECTED_GB * 5 / 100))  # Simplified: $0.05/GB/month

echo "Protected Items: $PROTECTED_GB"
echo "Estimated Monthly Cost: \$$MONTHLY_COST"
echo "Cost Allocation: IT-001 cost center"
```

**Talking Points**:
- "FinOps tags enable cost allocation by business unit"
- "Azure Monitor alerts when spending exceeds budget"
- "Log Analytics queries provide daily cost tracking"

### Scenario 4: Compliance Audit Trail (8 minutes)

**Objective**: Show compliance audit logging for RESTRICTED workloads

```bash
# 1. Show compliance policy definitions
echo "=== Compliance Policies (CAF) ==="
az policy definition list \
  --query "[?contains(displayName, 'compliance') || contains(displayName, 'backup')].{name:displayName, effect:policyRule.effect}"

# 2. Run compliance audit query
echo "=== Compliance Audit Trail (Last 24h) ==="
az monitor log-analytics query \
  --workspace $(az resource show -g rg-backup-enterprise-operations -n law-backup-enterprise --resource-type Microsoft.OperationalInsights/workspaces --query id -o tsv) \
  --analytics-query "@$(cat ../queries/compliance-audit-trail.kql)"

# 3. Show soft delete status (ransomware protection)
echo "=== Soft Delete Status (14-day Recovery) ==="
az backup vault backup-properties show \
  -g rg-backup-enterprise-protection \
  -n rsv-backup-enterprise-cc \
  | jq '.softDeleteFeatureState'

# 4. Show immutable lock status
echo "=== Immutable Vault Lock (Permanent) ==="
az backup vault get \
  -g rg-backup-enterprise-protection \
  -n rsv-backup-enterprise-cc \
  | jq '.properties.immutabilitySettings.state'
```

**Talking Points**:
- "Immutable lock proves backups are protected from unauthorized deletion (compliance proof)"
- "Audit trail shows who modified backup policies and when"
- "Soft delete provides 14-day ransomware recovery window"

---

## Validation: Pre-Demo Checklist

| # | Item | Pass? |
|---|------|-------|
| 1 | 3 RGs created with tags | ☐ |
| 2 | RSV + Backup Vault deployed | ☐ |
| 3 | Soft delete enabled (14-day) | ☐ |
| 4 | Immutable lock active | ☐ |
| 5 | Private endpoints created | ☐ |
| 6 | Bastion host deployed | ☐ |
| 7 | 5 RBAC roles assigned | ☐ |
| 8 | Azure Policy enforcing tags | ☐ |
| 9 | Log Analytics connected | ☐ |
| 10 | All 4 KQL queries saved | ☐ |

---

## Operational Runbooks (Reference)

Four runbooks provided in SPEC.md:

1. **Deployment Runbook** — Day 1 setup (covered above)
2. **Operational Management Runbook** — Daily/weekly/monthly checks
3. **Incident Response Runbook** — Ransomware recovery procedures
4. **Decommissioning Runbook** — End-of-life cleanup

See SPEC.md "Operational Runbooks" section for detailed procedures.

---

## Cleanup

```bash
# Delete all 3 resource groups
az group delete -n rg-backup-enterprise-workload --yes --no-wait
az group delete -n rg-backup-enterprise-protection --yes --no-wait
az group delete -n rg-backup-enterprise-operations --yes --no-wait

# Verify deletion (should return empty after ~5 minutes)
az group list --query "[?contains(name, 'enterprise')]"
```

**Estimated Cost**: $60-80/day (2 vaults + multiple RGs + private endpoints + Bastion)

---

## Troubleshooting

### Issue: "Private Endpoint creation failed: Service provider not found"

```bash
# Ensure providers are registered
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.RecoveryServices

# Wait 2-3 minutes, then retry deployment
```

### Issue: "Bastion deployment timed out"

```bash
# Bastion can take 10-15 minutes. Check status:
az network bastion list -g rg-backup-enterprise-operations --query "[].provisioningState"

# Wait for "Succeeded" state before proceeding
```

### Issue: "RBAC role assignment failed: Group not found"

```bash
# Verify group exists
az ad group list --filter "displayName eq 'Enterprise-Backup-Admins'" --query "[0].id"

# Update parameters.bicepparam with correct object ID
```

---

## Next Steps

After successful Pattern D deployment:

1. **Enroll Production Workloads**: Tag and register actual VMs in backup policies
2. **Configure Alerts**: Test backup job alerts and budget alerts
3. **Run Restore Drills**: Monthly restore tests to validate RTO/RPO
4. **Implement SIEM Integration**: Connect Azure Sentinel for security monitoring
5. **Establish Support Model**: 24/7 on-call support, escalation procedures

---

## Support & References

- **GitHub Issues**: https://github.com/KrishnaDistributedcomputing/AzureAIDeployments/issues
- **CAF Documentation**: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/
- **Azure Backup Best Practices**: https://learn.microsoft.com/en-us/azure/backup/backup-azure-backup-faq
- **Backup Team**: backup-team@company.com
- **Enterprise Architecture**: enterprise-arch@company.com

**Last Updated**: 2026-06-23
