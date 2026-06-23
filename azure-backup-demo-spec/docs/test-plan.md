# Azure Backup Demo Test Plan

## Deployment tests

| Test ID | Test | Expected result |
|---|---|---|
| T-001 | Deploy Bicep template | Resource groups and resources deploy successfully |
| T-002 | Validate naming | Names match demo naming standard |
| T-003 | Validate tags | Environment, Workload, Owner, CostCenter, AutoDeleteAfter tags exist |
| T-004 | Validate VM network posture | VM has no public IP and NSG denies inbound Internet traffic |
| T-005 | Validate diagnostics | Vault diagnostics point to Log Analytics |

## Backup tests

| Test ID | Test | Expected result |
|---|---|---|
| T-101 | Enable VM backup | VM appears as a protected item |
| T-102 | Trigger VM backup | Backup job is created and succeeds |
| T-103 | View VM recovery point | Recovery point is visible |
| T-104 | Enable Azure Files backup | File share appears as protected |
| T-105 | Trigger Azure Files backup | Backup job completes successfully |

## Restore tests

| Test ID | Test | Expected result |
|---|---|---|
| T-201 | Restore VM disk | Disk restore completes |
| T-202 | File-level restore | Deleted file is recovered |
| T-203 | Restore Azure file share item | File or share data is recovered |
| T-204 | Validate restored data | Restored content matches expected sample |

## Security tests

| Test ID | Test | Expected result |
|---|---|---|
| T-301 | Verify soft delete | Soft delete is enabled |
| T-302 | Attempt backup item deletion | Deleted item is retained by soft delete |
| T-303 | Validate RBAC | Non-authorized user cannot delete backup items |
| T-304 | Validate alerting | Backup alert path is functional |
