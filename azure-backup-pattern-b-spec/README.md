# Pattern B: Ransomware Resilience — Azure Backup Spec-Driven Deployment

**Audience**: Security stakeholders, business continuity managers, backup administrators

**Focus**: Ransomware-resilience controls, role-based access separation, soft delete protection, immutable vault locks, automated alerting

**Duration**: 45-60 minutes (demo + explanation)

## What's included

- **SPEC.md**: Comprehensive specification with architecture, backup policies, RBAC model, KQL queries, and presenter talking points
- **Deployment parameters**: Azure defaults, compliance settings, alert thresholds
- **Bicep infrastructure** (to be created): Vault with soft delete + immutable lock, RBAC role assignments, Log Analytics diagnostics
- **PowerShell scripts** (to be created): Deploy, seed demo data, trigger backups, demonstrate soft delete recovery
- **Runbook samples** (to be created): 3 restore workflows (file-level, disk-level, soft delete recovery)

## Quick start

### Prerequisites

```powershell
# Verify resource providers
az provider register --namespace Microsoft.RecoveryServices
az provider register --namespace Microsoft.DataProtection
az provider register --namespace Microsoft.OperationalInsights
```

### Deploy (placeholder — scripts to be implemented)

```powershell
# Deploy infrastructure
./deploy.ps1 -EnvironmentName backup-resilience -Location canadacentral -Owner security-team

# Run validation
./validate-backup.ps1

# Trigger demo backup
./trigger-backup.ps1

# Demonstrate soft delete recovery
./restore-soft-delete.ps1
```

## Key sections in SPEC.md

1. **RBAC Separation Model** — Why Backup Operator ≠ Backup Administrator
2. **Soft Delete & Immutable Locks** — Two-layer ransomware protection
3. **Restore Workflows** — 3 scenarios: file-level, disk-level, soft delete recovery
4. **KQL Monitoring** — Detect ransomware patterns in Log Analytics
5. **Presentation Talking Points** — How to explain ransomware resilience to security stakeholders

## Success criteria

- ✅ RBAC roles assigned; verify Backup Operator cannot modify policy
- ✅ Soft delete enabled (14-day recovery window)
- ✅ Immutable vault lock applied
- ✅ At least one backup job completed
- ✅ File-level restore demonstrated
- ✅ Soft delete recovery demonstrated (delete and undelete backup)
- ✅ Azure Monitor alerts trigger for test failures
- ✅ Presenter confidently explains ransomware resilience model

## Typical demo flow

1. **Setup** (5 min): Explain RBAC separation model and vault protections
2. **Demo vault** (5 min): Show soft delete enabled, immutable lock applied
3. **Demo restore** (10 min): File-level restore, disk restore, soft delete recovery
4. **Monitor** (5 min): Show Log Analytics queries for access audit trail
5. **Q&A** (10 min): Address ransomware concerns and recovery SLAs

## Next steps

1. Implement deploy.ps1 with RBAC role assignments
2. Implement restore demonstration scripts
3. Configure Azure Monitor alerts
4. Create operational runbooks for incident response

## References

- [SPEC.md](SPEC.md) — Full specification
- [Azure Backup Security Best Practices](https://learn.microsoft.com/azure/backup/backup-security-best-practices)
- [Soft Delete in Azure Backup](https://learn.microsoft.com/azure/backup/backup-azure-security-feature-cloud)
- [Immutable Vault Locks](https://learn.microsoft.com/azure/backup/backup-azure-security-feature-immutability)
