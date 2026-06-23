# Azure Backup Demo Runbook

## 1. Deploy

```powershell
./scripts/deploy.ps1 `
  -Location canadacentral `
  -EnvironmentName backup-demo `
  -Owner krishna `
  -AdminPassword (Read-Host -AsSecureString "VM admin password")
```

## 2. Seed Azure Files demo data

Use the `storageAccountName` output from deployment.

```powershell
./scripts/seed-demo-data.ps1 `
  -ResourceGroupName rg-backup-demo-core `
  -StorageAccountName <storage-account-name> `
  -FileShareName demo-share
```

## 3. Trigger backup

```powershell
./scripts/trigger-backup.ps1 `
  -CoreResourceGroupName rg-backup-demo-core `
  -ProtectionResourceGroupName rg-backup-demo-protection `
  -VaultName rsv-backup-demo-cc `
  -VmName vm-win-backup-demo-01 `
  -StorageAccountName <storage-account-name> `
  -FileShareName demo-share
```

## 4. Validate jobs and protected items

```powershell
./scripts/validate-backup.ps1 `
  -ProtectionResourceGroupName rg-backup-demo-protection `
  -VaultName rsv-backup-demo-cc
```

## 5. Restore walkthrough

Use the Azure portal for the presenter-friendly restore flow:

1. Open Recovery Services vault `rsv-backup-demo-cc`.
2. Select Backup items.
3. Select Azure Virtual Machine.
4. Select `vm-win-backup-demo-01`.
5. Choose Restore VM, Restore disks, or File Recovery.
6. Select a recovery point.
7. Execute restore or show pre-staged restored output.

## 6. Security walkthrough

- Show soft delete setting.
- Explain deleted backup item retention.
- Show immutable vault setting without locking it in disposable demos.
- Review backup roles and restore permissions.
- Show diagnostic logs and failed backup query.

## 7. Cleanup

```powershell
./scripts/cleanup.ps1
```

Use `-Force` only when cleanup behavior has already been reviewed.
