# Pattern D: Enterprise Landing Zone — Azure Backup Governance & Operations

**Audience**: Enterprise architects, cloud governance officers, operations teams, FinOps teams

**Focus**: CAF-aligned governance, three-tier resource group separation, policy-driven compliance, cost controls, private endpoint security, operational runbooks

**Duration**: 60-90 minutes (deep-dive + operational handoff)

## What's included

- **SPEC.md**: Comprehensive enterprise specification with CAF alignment, governance model, RBAC design, runbooks
- **Architecture diagram**: Three-tier resource group hierarchy with tagging strategy
- **Tagging strategy**: Mandatory tags enforced via Azure Policy (environment, cost-center, backup-policy, compliance-level, owner)
- **RBAC design**: 5 role tiers from Backup Admin to Vault Reader
- **Bicep infrastructure** (to be created): Three resource groups, both vault types, private endpoints, Bastion, Azure Policy
- **PowerShell scripts** (to be created): Deploy with policy enforcement, tag validation, role assignment
- **Four operational runbooks** (to be created):
  - Deployment runbook (Day 1 setup)
  - Operational management (Weekly/monthly tasks)
  - Incident response (Ransomware, data corruption)
  - Decommissioning (End-of-life workload cleanup)
- **Cost allocation model**: Backup cost by cost center, retention tier, compliance level

## Quick start

### Prerequisites

```powershell
# Verify all required resource providers
$providers = @(
  "Microsoft.RecoveryServices",
  "Microsoft.DataProtection",
  "Microsoft.OperationalInsights",
  "Microsoft.Network",
  "Microsoft.Compute",
  "Microsoft.Authorization"
)
foreach ($provider in $providers) {
  az provider register --namespace $provider
}

# Verify user has Subscription Contributor role
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Deploy (placeholder — scripts to be implemented)

```powershell
# Deploy enterprise landing zone with all governance controls
./deploy.ps1 `
  -EnvironmentName backup-enterprise `
  -Location canadacentral `
  -SubscriptionId (az account show --query id -o tsv) `
  -ManagementGroupId "your-mg-id"

# Validate RBAC roles assigned
./validate-rbac.ps1

# Run cost tracking queries
./query-cost-by-costcenter.ps1

# Demonstrate operational runbooks
./runbook-deployment.ps1   # Day 1 setup
./runbook-operations.ps1   # Weekly management
./runbook-incident.ps1     # Ransomware response
./runbook-decommission.ps1 # End-of-life cleanup
```

## Key sections in SPEC.md

1. **Enterprise Governance Model** — Three-tier resource groups aligned with CAF
2. **Tagging Strategy** — Mandatory tags enforced by Azure Policy
3. **RBAC Design** — 5-role separation of duties model
4. **Cost Allocation** — FinOps model with cost center chargeback
5. **Four Operational Runbooks** — Deployment, operations, incident response, decommissioning
6. **Monitoring & Alerting** — KQL queries for compliance, cost, SLA tracking
7. **Definition of Done** — Enterprise deployment checklist

## Success criteria

- ✅ Three resource groups created with correct ownership (workload, protection, operations)
- ✅ All resources properly tagged (environment, cost-center, backup-policy, compliance-level)
- ✅ Azure Policy enforces mandatory tagging (prevents non-compliant deployments)
- ✅ RBAC roles assigned (Backup Admin, Operator, Restore Operator, Readers)
- ✅ Both vaults deployed with soft delete + immutable lock
- ✅ Private endpoints configured; no public IP exposure
- ✅ Bastion deployed for secure administrative access
- ✅ Log Analytics workspace operational with cost tracking queries
- ✅ Azure Monitor budgets and alerts configured
- ✅ All four runbooks documented and validated
- ✅ Knowledge transfer completed to backup operations team
- ✅ Post-deployment support plan established

## Typical demo flow

1. **CAF alignment** (10 min): Show three-tier resource group model, tagging strategy
2. **Governance controls** (10 min): Demonstrate Azure Policy enforcement, tag validation
3. **RBAC model** (10 min): Explain separation of duties, verify role permissions
4. **Vault security** (10 min): Show private endpoints, immutable lock, soft delete
5. **Cost tracking** (10 min): Run Log Analytics queries, show cost by cost center
6. **Runbook walkthrough** (20 min): Review four operational runbooks, discuss handoff
7. **Q&A** (10 min): Enterprise architecture and operations questions

## Key sections for enterprise stakeholders

### For CIO/Cloud Governance Officer
- CAF alignment: Backup governance matches enterprise architecture standards
- Policy enforcement: Azure Policy prevents non-compliant deployments
- Audit trail: Full compliance audit available in Log Analytics

### For Operations/FinOps Team
- Cost tracking: Backup costs by cost center, compliance level, workload type
- Budget controls: Alerts for overage, forecasting for CapEx planning
- Runbooks: Complete procedures for deployment, operations, incident response, cleanup

### For Security Team
- RBAC separation: Prevents unauthorized vault modifications
- Private endpoints: Zero-trust network architecture
- Soft delete + immutable lock: Ransomware and accidental deletion protection
- Audit logging: Complete access trail for compliance

### For Workload Teams
- Self-service: Auto-enrollment based on tags (no approval bottleneck)
- Clear policies: Retention, redundancy driven by compliance level tag
- Predictable costs: Chargeback model visible in monthly bill

## Next steps

1. Implement deploy.ps1 with three resource groups and mandatory tags
2. Create Azure Policy definitions for tag enforcement
3. Implement RBAC role assignments via Bicep
4. Deploy private endpoints and Bastion
5. Create operational runbooks with detailed steps
6. Establish post-deployment support model

## Operational continuity

**Day 1**: Deploy infrastructure, assign RBAC, validate all systems

**Week 1**: Run all four runbooks for first time; document any missing steps

**Month 1**: FinOps review — analyze backup costs, adjust retention policies

**Quarterly**: Enterprise architecture review — ensure policies still align with business

## Key talking points

1. "This backup architecture aligns with Microsoft Cloud Adoption Framework governance"
2. "Tag-driven retention tiers save 40-60% vs. uniform retention"
3. "Azure Policy prevents manual compliance checks — it's automatic"
4. "Private endpoints + Bastion eliminate internet exposure for backup infrastructure"
5. "Four runbooks ensure consistent operations across team rotations"
6. "Multi-region GRS + immutable lock = guaranteed recovery even from ransomware"

## References

- [SPEC.md](SPEC.md) — Full specification
- [Cloud Adoption Framework: Governance](https://learn.microsoft.com/azure/cloud-adoption-framework/govern/)
- [Azure Policy overview](https://learn.microsoft.com/azure/governance/policy/overview)
- [Azure Backup Security Best Practices](https://learn.microsoft.com/azure/backup/backup-security-best-practices)
- [Azure Cost Management + Billing](https://learn.microsoft.com/azure/cost-management-billing/)
