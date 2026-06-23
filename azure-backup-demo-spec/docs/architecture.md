# Azure Backup Demo Architecture

## Logical architecture

```text
Azure Subscription
  rg-backup-demo-core
    vnet-backup-demo
    vm-win-backup-demo-01 or vm-linux-backup-demo-01
    data disk
    storage account
    Azure file share: demo-share

  rg-backup-demo-protection
    Recovery Services vault: rsv-backup-demo-cc
      pol-vm-daily-demo
      pol-files-daily-demo
      soft delete enabled
      diagnostics to Log Analytics
    Backup vault: bv-backup-demo-cc
      optional newer workload backup pattern
      diagnostics to Log Analytics

  rg-backup-demo-ops
    Log Analytics workspace: law-backup-demo-cc
    optional action group
```

## Resource group model

| Resource group | Purpose |
|---|---|
| rg-backup-demo-core | Demo workload resources such as VM, disk, storage account, file share |
| rg-backup-demo-protection | Recovery Services vault, Backup vault, backup policies, RBAC |
| rg-backup-demo-ops | Log Analytics workspace, action groups, alerts, dashboards |

## Security posture

- No public IP is created for the VM.
- Network security group denies inbound Internet traffic.
- VM uses managed identity.
- Soft delete is enabled by default where supported.
- Immutable vault is parameterized but disabled by default for clean demo teardown.
- RBAC personas can be assigned by passing group principal IDs.
