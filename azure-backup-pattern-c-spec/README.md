# Pattern C: Modern Workloads — Azure Backup Vault Types & Differentiation

**Audience**: Platform teams, DevOps engineers, infrastructure architects, cloud center of excellence

**Focus**: Backup vault vs. Recovery Services vault, workload placement strategies, managed disk backup, AKS cluster backup, Blob operational backup

**Duration**: 30-40 minutes (demo + explanation)

## What's included

- **SPEC.md**: Comprehensive specification with vault comparison matrix, workload placement, backup policies by vault type
- **Architecture diagram**: Vault separation model showing RSV for traditional workloads, Backup vault for cloud-native
- **Workload placement table**: Which Azure services go to which vault, why, and restore strategies
- **Bicep infrastructure** (to be created): Both Recovery Services and Backup vaults, optional managed disk, optional AKS cluster
- **PowerShell scripts** (to be created): Deploy both vaults, demonstrate disk snapshot restore, blob operational backup restore
- **Cost comparison** (to be created): RSV vs. Backup vault monthly costs by workload type

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
# Deploy both vaults
./deploy.ps1 -EnvironmentName backup-modern -Location eastus

# Deploy optional managed disk for demo
./deploy.ps1 -EnvironmentName backup-modern -DeployManagedDisk $true

# Demonstrate disk restore
./restore-disk-snapshot.ps1

# Demonstrate blob operational backup restore
./restore-blob-operational.ps1
```

## Key sections in SPEC.md

1. **Vault Separation Model** — Why two vaults exist and when to use each
2. **Workload Placement Table** — Decision matrix: VM → RSV, Managed Disk → Backup vault, etc.
3. **Backup policies by vault** — Different policy structures for RSV vs. Backup vault
4. **Demo scenarios** — 4 hands-on scenarios with talking points
5. **Cost comparison** — RSV vs. Backup vault pricing for different workloads

## Success criteria

- ✅ Both Recovery Services vault and Backup vault deployed
- ✅ Platform team understands vault placement (RSV for IaaS, Backup vault for cloud-native)
- ✅ At least one workload in each vault (VM in RSV, managed disk in Backup vault)
- ✅ Backup jobs completed in both vaults
- ✅ Managed disk snapshot restore demonstrated
- ✅ Blob operational backup restore demonstrated
- ✅ Log Analytics queries show workload distribution across vault types
- ✅ Platform team can articulate cost trade-offs (retention vs. vault type)

## Typical demo flow

1. **Explain vaults** (5 min): Show vault separation model, discuss cloud-native vs. traditional
2. **Deploy workloads** (5 min): Show VM in RSV, managed disk in Backup vault
3. **Demo disk restore** (5 min): Restore snapshot to new disk, attach to test VM
4. **Demo blob restore** (5 min): Delete blob, restore from operational backup
5. **Cost analysis** (5 min): Show cost differences by retention, redundancy, vault type
6. **Q&A** (10 min): Platform team questions on workload placement

## Next steps

1. Implement deploy.ps1 with both vault types
2. Implement optional managed disk and AKS cluster deployment
3. Create restore demonstration scripts
4. Build cost comparison dashboard in Log Analytics

## Key talking points

- "Recovery Services vault is mature (10+ years), Backup vault is cloud-native (2023+)"
- "Backup vault is cheaper for short-retention cloud workloads"
- "One vault per workload family simplifies architecture"
- "Retention flexibility: RSV allows 1-9999 days, Backup vault enforces SLA-based retention"

## References

- [SPEC.md](SPEC.md) — Full specification
- [Azure Backup vault vs. Recovery Services vault](https://learn.microsoft.com/azure/backup/backup-vault-overview)
- [Manage Backup vault](https://learn.microsoft.com/azure/backup/backup-vault-manage)
- [Operational backup for blobs](https://learn.microsoft.com/azure/backup/blob-backup-overview)
