# Spec-Driven Development: Azure Backup Demo Environment

Document version: 1.0

Target audience: Cloud engineering, customer engineering, solution architecture, sales engineering, demo presenters

Primary objective: Build a repeatable Azure Backup demo environment that can show backup configuration, policy design, restore workflows, operational monitoring, and ransomware-resilience controls.

## Deployment scope

This implementation provides the deployable baseline for the specification:

- Resource groups for workload, protection, and operations.
- Demo VM substrate with network, NIC, OS disk, and data disk.
- Storage account and Azure file share for delete-and-restore scenarios.
- Recovery Services vault with short-retention VM and Azure Files policies.
- Optional Backup vault for newer backup workloads such as Azure Disk Backup.
- Log Analytics workspace and diagnostic settings.
- Optional action group and optional RBAC role assignments.
- Scripts and runbooks for backup-now, validation, restore walkthrough, and cleanup.

## Demo defaults

| Parameter | Default |
|---|---|
| environmentName | backup-demo |
| location | canadacentral |
| owner | krishna |
| deployWindowsVm | true |
| deployLinuxVm | false |
| deployAzureFiles | true |
| deployDiskBackup | false |
| enableSoftDelete | true |
| enableImmutableVault | false |
| retentionDays | 7 |
| storageRedundancy | LRS |

## Definition of done

The demo is ready when the environment deploys successfully, VM and Azure Files backup policies exist, backup diagnostics are connected to Log Analytics, at least one backup job can be triggered, a recovery point is visible, one restore workflow is demonstrated, soft delete behavior is explained, and cleanup has been tested.
