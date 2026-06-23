# Presenter Notes

## Opening

Today we are demonstrating how Azure Backup protects core Azure workloads with policy-driven backup, centralized vault management, restore workflows, and built-in protection controls such as soft delete and optional immutability.

## Vault explanation

Recovery Services vaults are used for Azure VM, Azure Files, SQL in Azure VM, SAP HANA in Azure VM, and hybrid backup scenarios. Backup vaults are used for newer data-source backup scenarios such as Azure Disk Backup, AKS Backup, and other supported data protection workloads.

## VM backup talking points

- The VM represents a small application server.
- The policy is intentionally short-retention for demo cost control.
- Recovery can be a full VM restore, disk restore, or file-level recovery.

## Azure Files talking points

- The file share represents shared application or business data.
- The seeded files support a delete-and-restore story.
- Azure Backup provides item-level restore workflows for file shares.

## Security talking points

- Backup is not just copying data.
- Restore control, deletion protection, monitoring, and RBAC separation are part of ransomware recovery posture.
- Do not lock immutability in disposable demos unless the teardown process is tested.

## Close

Azure Backup provides native, policy-driven protection with restore validation, operational visibility, and security controls that support business continuity and ransomware recovery planning.
