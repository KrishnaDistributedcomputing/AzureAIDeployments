# Spec-Driven Development: Azure Backup Pattern D — Enterprise Landing Zone

Document version: 1.0

Target audience: Enterprise architects, cloud governance officers, CAF (Cloud Adoption Framework) practitioners, operations/FinOps teams, security architects

Primary objective: Demonstrate production-ready Azure Backup governance aligned with Microsoft Cloud Adoption Framework (CAF). This pattern emphasizes separation of concerns across workload, protection, and operations resource groups; policy-driven compliance; cost controls through retention and redundancy decisions; secure access patterns via Bastion and private endpoints; and operational handoff documentation for enterprise deployment.

## Deployment scope

This implementation provides an enterprise-grade baseline for production workload protection:

- **Three-tier resource group separation** (CAF-aligned):
  - **Workload RG**: Application infrastructure (VMs, databases, storage)
  - **Protection RG**: Backup infrastructure (Recovery Services vault, Backup vault, private endpoints)
  - **Operations RG**: Monitoring, alerting, compliance audit logs
- **Tagging & governance**:
  - Mandatory tags: `environment`, `cost-center`, `owner`, `backup-policy`, `retention-days`, `compliance-level`
  - Policy-driven tag enforcement (Azure Policy)
  - Automatic backup enrollment based on workload tags
- **Network security** (zero-trust model):
  - Private endpoints for vault access (no internet exposure)
  - Azure Bastion for administrative access to backup vaults
  - Network security groups with backup-specific rules
  - Disabled public IP access to recovery vaults
- **Cost controls**:
  - Retention decisions by compliance level (7-30-90 days)
  - Redundancy choices mapped to RTO/RPO requirements
  - Chargeback tags for cost center allocation
  - Budget alerts for backup spend thresholds
- **Compliance & audit**:
  - Immutable vault lock for HIPAA/PCI-DSS/SOX workloads
  - Soft delete enabled for ransomware protection (all workloads)
  - Role-based access control (RBAC) with operator separation
  - Log Analytics integration with SOC/SIEM (Azure Sentinel)
  - Diagnostic settings to central audit storage account
- **Operational runbooks** (handoff documentation):
  - Deployment runbook (IaC + manual steps)
  - Operational runbook (backup policy management, restore procedures)
  - Incident response runbook (ransomware, data corruption, accidental deletion)
  - Decommissioning runbook (cleanup, data retention, archive)

## Demo defaults

| Parameter | Default | Rationale |
|---|---|---|
| environmentName | backup-enterprise | Indicates production-grade focus |
| location | canadacentral | Regional hub for North America |
| owner | enterprise-platform | Central IT/platform team |
| **Workload RG** | rg-backup-enterprise-workload | Workload team ownership |
| **Protection RG** | rg-backup-enterprise-protection | Backup team ownership |
| **Operations RG** | rg-backup-enterprise-operations | SOC/audit team ownership |
| deployRecoveryServicesVault | true | Primary vault for VMs, databases |
| deployBackupVault | true | Secondary vault for managed disks, Blob |
| deployPrivateEndpoint | true | **Key differentiator** — zero-trust network |
| deployBastion | true | Administrative access without RDP/SSH exposure |
| deployAzurePolicy | true | Tag enforcement and compliance automation |
| deployPrivateLink | true | Backup vault accessible only via vnet |
| enableSoftDelete | true | **Required** — ransomware protection |
| enableImmutableVault | true | **Required for compliance** — audit lock |
| enableAzureSentinel | false | Optional: SIEM integration |
| costCenterTag | enterprise-backup | Chargeback allocation |
| complianceLevels | [INTERNAL, CONFIDENTIAL, RESTRICTED] | Retention tiers (7, 30, 90 days) |
| softDeleteRetentionDays | 14 | Minimum ransomware recovery window |

## Architecture

### Enterprise governance model

```
┌────────────────────────────────────────────────────────────────┐
│ ENTERPRISE RESOURCE HIERARCHY (Azure Management Groups)        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│ Management Group: "Backup"                                     │
│ ├─ Policy: Enforce tagging (environment, cost-center, policy)  │
│ ├─ Policy: Require soft delete on all Recovery Services vaults│
│ ├─ Policy: Require private endpoints for vault access         │
│ └─ Policy: Audit immutable vault lock deployment              │
│                                                                │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ SUBSCRIPTION: "Production-Backup-001"                    │  │
│ ├──────────────────────────────────────────────────────────┤  │
│ │                                                           │  │
│ │ ┌─────────────────────────────────────────────────────┐  │  │
│ │ │ WORKLOAD RG: rg-backup-enterprise-workload          │  │  │
│ │ ├─────────────────────────────────────────────────────┤  │  │
│ │ │ Tags:                                               │  │  │
│ │ │ - environment: production                           │  │  │
│ │ │ - cost-center: IT-001                               │  │  │
│ │ │ - backup-policy: daily-7-day                        │  │  │
│ │ │ - compliance-level: CONFIDENTIAL                    │  │  │
│ │ │                                                     │  │  │
│ │ │ Resources:                                          │  │  │
│ │ │ ✓ Production VMs (Windows, Linux)                   │  │  │
│ │ │ ✓ Database servers                                  │  │  │
│ │ │ ✓ Azure Files (sensitive data)                      │  │  │
│ │ │ ✓ Managed disks (application tier)                  │  │  │
│ │ └─────────────────────────────────────────────────────┘  │  │
│ │                                                           │  │
│ │ ┌─────────────────────────────────────────────────────┐  │  │
│ │ │ PROTECTION RG: rg-backup-enterprise-protection     │  │  │
│ │ ├─────────────────────────────────────────────────────┤  │  │
│ │ │                                                     │  │  │
│ │ │ ┌──────────────────────────────────────────────┐   │  │  │
│ │ │ │ Recovery Services Vault                      │   │  │  │
│ │ │ │ - Soft delete: ENABLED (14 days)            │   │  │  │
│ │ │ │ - Immutable lock: ENABLED                    │   │  │  │
│ │ │ │ - GRS replication: ENABLED                   │   │  │  │
│ │ │ │ - Private endpoint: prod-vault.privatelink   │   │  │  │
│ │ │ │ - Diagnostic settings → SOC workspace        │   │  │  │
│ │ │ └──────────────────────────────────────────────┘   │  │  │
│ │ │                                                     │  │  │
│ │ │ ┌──────────────────────────────────────────────┐   │  │  │
│ │ │ │ Backup Vault                                 │   │  │  │
│ │ │ │ - Soft delete: ENABLED (14 days)            │   │  │  │
│ │ │ │ - Immutable lock: ENABLED                    │   │  │  │
│ │ │ │ - LRS replication                            │   │  │  │
│ │ │ │ - Private endpoint: prod-backup.privatelink  │   │  │  │
│ │ │ │ - Diagnostic settings → SOC workspace        │   │  │  │
│ │ │ └──────────────────────────────────────────────┘   │  │  │
│ │ │                                                     │  │  │
│ │ │ ┌──────────────────────────────────────────────┐   │  │  │
│ │ │ │ Network Security (Zero-Trust)                │   │  │  │
│ │ │ │ - Private endpoints (both vaults)            │   │  │  │
│ │ │ │ - NSGs block internet access                 │   │  │  │
│ │ │ │ - Service endpoints for AzureBackup service │   │  │  │
│ │ │ └──────────────────────────────────────────────┘   │  │  │
│ │ │                                                     │  │  │
│ │ └─────────────────────────────────────────────────────┘  │  │
│ │                                                           │  │
│ │ ┌─────────────────────────────────────────────────────┐  │  │
│ │ │ OPERATIONS RG: rg-backup-enterprise-operations     │  │  │
│ │ ├─────────────────────────────────────────────────────┤  │  │
│ │ │                                                     │  │  │
│ │ │ ┌──────────────────────────────────────────────┐   │  │  │
│ │ │ │ Log Analytics Workspace (SOC Audit)          │   │  │  │
│ │ │ │ - Backup job events                          │   │  │  │
│ │ │ │ - Vault access & compliance audit            │   │  │  │
│ │ │ │ - Cost tracking (backup vs budget)           │   │  │  │
│ │ │ │ - Ransomware detection queries               │   │  │  │
│ │ │ └──────────────────────────────────────────────┘   │  │  │
│ │ │                                                     │  │  │
│ │ │ ┌──────────────────────────────────────────────┐   │  │  │
│ │ │ │ Storage Account (Audit Logs)                 │   │  │  │
│ │ │ │ - Immutable blob storage (compliance)        │   │  │  │
│ │ │ │ - 7-year retention (SOX/HIPAA)              │   │  │  │
│ │ │ │ - Blob versioning enabled                    │   │  │  │
│ │ │ └──────────────────────────────────────────────┘   │  │  │
│ │ │                                                     │  │  │
│ │ │ ┌──────────────────────────────────────────────┐   │  │  │
│ │ │ │ Azure Monitor (Alerts & Notifications)       │   │  │  │
│ │ │ │ - Backup failure alerts (email/SMS/webhook)  │   │  │  │
│ │ │ │ - Budget overage alerts (cost controls)      │   │  │  │
│ │ │ │ - Vault deletion attempt alerts (security)   │   │  │  │
│ │ │ └──────────────────────────────────────────────┘   │  │  │
│ │ │                                                     │  │  │
│ │ │ ┌──────────────────────────────────────────────┐   │  │  │
│ │ │ │ Azure Bastion (Admin Access)                 │   │  │  │
│ │ │ │ - RDP/SSH without public IP                  │   │  │  │
│ │ │ │ - Audit logging to Log Analytics             │   │  │  │
│ │ │ │ - JIT access control (optional)              │   │  │  │
│ │ │ └──────────────────────────────────────────────┘   │  │  │
│ │ │                                                     │  │  │
│ │ └─────────────────────────────────────────────────────┘  │  │
│ │                                                           │  │
│ └──────────────────────────────────────────────────────────┘  │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Tagging strategy (CAF-aligned)

### Mandatory tags (enforced via Azure Policy)

| Tag | Values | Usage | Impact |
|---|---|---|---|
| `environment` | production, staging, development, sandbox | Controls retention/redundancy, cost allocation | Prod = GRS, Dev = LRS |
| `cost-center` | IT-001, IT-002, ..., BU-Finance | Chargeback, cost tracking | Budget alerts by cost center |
| `backup-policy` | daily-7, daily-30, weekly-90, hourly | Backup schedule and retention | Auto-enrollment to vault |
| `compliance-level` | INTERNAL, CONFIDENTIAL, RESTRICTED | Compliance/retention tier | RESTRICTED = 90 day retention + immutable |
| `owner` | team@company.com | Escalation and handoff | Alert routing, access control |
| `rg-function` | workload, protection, operations | Resource group purpose | Visibility for audit |

### Example tag assignments

**Production VM (sensitive data):**
```
environment: production
cost-center: IT-001
backup-policy: daily-30
compliance-level: CONFIDENTIAL
owner: database-team@company.com
data-classification: sensitive
```

**Development VM (non-critical):**
```
environment: development
cost-center: IT-001
backup-policy: daily-7
compliance-level: INTERNAL
owner: devops-team@company.com
data-classification: internal
```

## Cost allocation & FinOps

### Backup cost model

```
Monthly Backup Cost = 
  (Protected Size [GB] × Vault Type × Redundancy) +
  (Restore Operations × Egress Charges) +
  (Retention Days × Storage Rate)

Example: 500GB VM, GRS, 30-day retention
= (500 × $0.05/GB × 1.5 GRS multiplier) + (egress) + (retention)
= $37.50 + egress + retention
≈ $50-75/month depending on restore frequency
```

### Retention tier recommendations

| Compliance Level | Retention | Use Cases | Estimated Cost |
|---|---|---|---|
| **INTERNAL** | 7 days | Non-critical dev/test | $20-30/month per 100GB |
| **CONFIDENTIAL** | 30 days | Production workloads, databases | $60-80/month per 100GB |
| **RESTRICTED** | 90 days | Healthcare, finance, compliance | $150-200/month per 100GB |

## RBAC design for enterprise

| Role | Permissions | User/Group |
|---|---|---|
| **Backup Administrator** | Full vault management, policy creation, retention decisions, immutable lock | Enterprise Backup team (2-3 people) |
| **Backup Operator** | Trigger backups, view recovery points, initiate restores (no policy changes) | Application teams (read-only to their workloads) |
| **Restore Operator** | Restore workflows only, no backup configuration | Incident response, DRP teams |
| **Vault Reader** | Read-only access to vault status, diagnostics, compliance audit | SOC, audit teams, CIO office |
| **Cost Analyst** | Query Log Analytics for backup costs, budget tracking | FinOps team |

## Operational runbooks

### Runbook 1: Deployment (Day 1)

**Steps**:
1. Validate subscription prerequisites (providers, quotas, limits)
2. Create management groups and apply Azure Policy
3. Create three resource groups with mandatory tags
4. Deploy Bicep templates (vaults, networking, monitoring)
5. Assign RBAC roles to team groups
6. Configure Log Analytics workspace for diagnostics
7. Validate all resources deployed successfully
8. Configure backup policies per compliance level
9. Enroll workload VMs in backup protection
10. Run first backup job and verify recovery point
11. Document deployment in Configuration Management Database (CMDB)
12. Schedule post-deployment review with stakeholders

**Duration**: 4-6 hours (mostly automation)

### Runbook 2: Operational Management (Daily/Weekly)

**Weekly checks** (Tuesday morning):
- Review backup job status dashboard in Log Analytics
- Verify all critical workloads have recent recovery points
- Check backup cost vs. budget thresholds
- Review any failed backup jobs
- Escalate failures to workload teams

**Monthly checks** (First Monday):
- Review retention policy effectiveness
- Analyze restore frequency and trending
- Optimize retention for cost savings where possible
- Update disaster recovery documentation
- Conduct FinOps review with cost center owners

### Runbook 3: Incident Response (On-Demand)

**Ransomware attack scenario**:
1. Detect: Monitor alert triggers on multiple failed backup jobs
2. Respond: Lock down vault (disable new backups, enable soft delete)
3. Investigate: Query Log Analytics for access patterns (who accessed vault)
4. Recover: Restore files/disks from pre-attack recovery point
5. Harden: Review RBAC, immutable lock, alert rules
6. Document: Post-incident review (RCA) and policy improvements

### Runbook 4: Decommissioning (End-of-life)

**Steps** (3-6 month notice):
1. Identify workloads reaching end-of-support or cloud migration
2. Determine data retention requirements (compliance archive)
3. Move backups to long-term storage (Archive tier) if needed
4. Plan recovery point final backup before decommission
5. Schedule deletion with stakeholder approval
6. Execute deletion and verify cleanup
7. Document data destruction certificate (compliance proof)

## Monitoring & alerting

### KQL Queries (Log Analytics)

**Query 1: Cost Tracking by Cost Center**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| extend CostCenter = tostring(parse_json(Tags)["cost-center"])
| summarize BackupsSizeGB = sum(todouble(BackupItemSize)), 
            JobCount = count() 
            by CostCenter
| extend EstimatedMonthlyCost = BackupsSizeGB * 0.05
```

**Query 2: Compliance Audit Trail (RESTRICTED workloads only)**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| where parse_json(Tags)["compliance-level"] == "RESTRICTED"
| where OperationName in ("CreateVault", "DeleteVault", "ModifyPolicy", "EnableSoftDelete")
| project TimeGenerated, Caller, OperationName, ResourceName, Status
| order by TimeGenerated desc
```

**Query 3: Restore Time SLA Compliance**
```kusto
AzureDiagnostics
| where OperationName == "Restore"
| extend DurationMins = (TimeGenerated - todouble(parse_json(Details)["StartTime"])) / 60
| summarize P50 = percentile(DurationMins, 50), 
            P95 = percentile(DurationMins, 95), 
            P99 = percentile(DurationMins, 99)
            by BackupItemType
| extend SLA_4Hour = iff(P95 < 240, "✓ PASS", "✗ FAIL")
```

**Query 4: Budget Alert (Monthly backup spend vs. budget)**
```kusto
AzureDiagnostics
| where ResourceType == "VAULTS"
| summarize TotalBackupGB = sum(todouble(BackupItemSize))
| extend EstimatedMonthlyCost = TotalBackupGB * 0.05
| extend BudgetStatus = iff(EstimatedMonthlyCost > 5000, "🔴 OVER", "🟢 OK")
```

### Alert Rules

| Alert | Condition | Severity | Action |
|---|---|---|---|
| **Backup Failure** | 3+ jobs failed in 1 hour | High | Email backup team + incident ticket |
| **Budget Overage** | Monthly spend > budget + 10% | Medium | Email FinOps team |
| **Vault Deletion Attempt** | Any DeleteVault operation | Critical | Immediate Slack alert + manager escalation |
| **Compliance Violation** | RESTRICTED workload backup disabled | High | Email compliance officer |
| **Restore SLA Breach** | Restore job > 4 hours | Medium | Email incident response team |

## Definition of done

The enterprise pattern deployment is complete when:

- ✅ Three resource groups created with correct ownership and tags
- ✅ Both Recovery Services and Backup vaults deployed with soft delete + immutable lock
- ✅ Private endpoints configured, public access disabled
- ✅ Azure Policy enforces mandatory tagging (tags cannot be deleted)
- ✅ RBAC roles assigned correctly (separation of duties verified)
- ✅ Log Analytics workspace operational with all diagnostic settings enabled
- ✅ Backup policies auto-enroll new VMs based on tags
- ✅ At least one full backup job completed and recovery point visible
- ✅ Azure Monitor alerts tested (intentional job failure triggers alert)
- ✅ Bastion deployed for administrative access (no public IPs exposed)
- ✅ Cost tracking queries in Log Analytics return expected results
- ✅ All four runbooks (deployment, operations, incident response, decommissioning) documented
- ✅ Enterprise architecture review completed and approved
- ✅ Knowledge transfer completed to backup operations team
- ✅ Post-deployment support plan established (escalation, SLAs, hours)

## Presenter talking points

1. **CAF alignment**: "This backup architecture aligns with Microsoft Cloud Adoption Framework governance model"
2. **Separation of duties**: "Each team owns their resource group, preventing unauthorized access"
3. **Cost optimization**: "Tag-driven retention tiers save 40-60% vs. uniform 90-day retention"
4. **Compliance automation**: "Azure Policy enforces backup controls; no manual compliance checks needed"
5. **Disaster recovery**: "Multi-region GRS + immutable lock ensures recovery even from ransomware"
6. **Operational handoff**: "Four runbooks ensure consistent operations across team rotations"

## Parameters (for Bicep deployment)

```bicep
param environmentName string = 'backup-enterprise'
param location string = 'canadacentral'
param owner string = 'enterprise-platform'
param workloadRgName string = 'rg-backup-enterprise-workload'
param protectionRgName string = 'rg-backup-enterprise-protection'
param operationsRgName string = 'rg-backup-enterprise-operations'
param deployPrivateEndpoint bool = true
param deployBastion bool = true
param deployAzurePolicy bool = true
param enableSoftDelete bool = true
param enableImmutableVault bool = true
param softDeleteRetentionDays int = 14
param vaultStorageRedundancy string = 'GRS'
param complianceLevels array = ['INTERNAL', 'CONFIDENTIAL', 'RESTRICTED']
param retentionByCompliance object = {
  INTERNAL: 7
  CONFIDENTIAL: 30
  RESTRICTED: 90
}
```

## Dependencies & prerequisites

- Azure subscription with Owner role for user initiating deployment
- All resource providers registered: RecoveryServices, DataProtection, Compute, Storage, Network, OperationalInsights, KeyVault
- Log Analytics workspace (create or reference existing)
- Azure AD groups defined: Backup Admin, Backup Operator, Restore Operator, Vault Readers
- Network: Vnet with private endpoint subnet, Bastion subnet
- Budget alerts configured in Azure Cost Management

## Success criteria

Pattern D demonstration is successful when:

1. **Governance**: All resources properly tagged; Azure Policy enforces compliance
2. **Security**: Private endpoints deployed; Bastion enabled; no public IP exposure
3. **Operations**: RBAC separation prevents unauthorized changes; audit trail visible
4. **Cost**: Log Analytics queries accurately track backup spend by cost center
5. **Compliance**: Immutable vault lock prevents deletion; soft delete protects ransomware scenarios
6. **Narrative**: Presenter confidently explains CAF governance model and operational handoff
7. **Enterprise readiness**: Teams can deploy and manage backups independently within governance guardrails
