# Azure Backup Demo Spec-Driven Deployment

This folder contains a deployable Azure Backup demo environment based on the Azure Backup demo specification.

## What it deploys

- Core workload resource group for demo VM, data disk, storage account, and Azure file share.
- Protection resource group for Recovery Services vault, VM backup policy, Azure Files backup policy, and optional Backup vault.
- Operations resource group for Log Analytics workspace and optional action group.
- Optional RBAC role assignments for backup admin, restore operator, and security reviewer personas.
- Scripts to deploy, seed data, trigger backup, validate backup jobs, and clean up.

## Quick start

```powershell
./scripts/deploy.ps1 `
  -Location canadacentral `
  -EnvironmentName backup-demo `
  -Owner krishna `
  -AdminPassword (Read-Host -AsSecureString "VM admin password")
```

For direct `az deployment sub create` usage with `infra/main.demo.bicepparam`, set `AZURE_BACKUP_DEMO_ADMIN_PASSWORD` or override `adminPassword` on the command line. The checked-in value is only a diagnostics placeholder.

## Recommended demo flow

1. Deploy the environment.
2. Seed demo data into Azure Files.
3. Enable or verify backup protection.
4. Trigger an initial backup.
5. Validate jobs and recovery points.
6. Demonstrate restore from the Azure portal.
7. Review soft delete, alerts, RBAC, and monitoring.
8. Run cleanup after the demo.

## Pattern deployment specs

- [Pattern A: Core Demo Environment](docs/pattern-a-core-demo-deployment.md) - full spec-driven deployment guide for the baseline VM and Azure Files demo.

## Notes

The Bicep deployment creates the demo substrate and core vault policies. Some Azure Backup operations, such as triggering on-demand backups and presenter-friendly restore workflows, are intentionally represented as scripts and runbook steps because they are operational actions rather than static infrastructure state.
