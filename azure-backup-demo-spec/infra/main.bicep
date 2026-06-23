targetScope = 'subscription'

@description('Azure region for all demo resources.')
param location string = 'canadacentral'

@description('Short environment name used in resource names and tags.')
param environmentName string = 'backup-demo'

@description('Short Azure region code used in names.')
param regionCode string = 'cc'

@description('Owner tag value.')
param owner string = 'krishna'

@description('Date or policy marker used by cleanup automation.')
param autoDeleteAfter string = 'review-before-delete'

@description('VM administrator username.')
param adminUsername string = 'azureadmin'

@secure()
@description('VM administrator password. Required for the demo VM.')
param adminPassword string

@description('Deploy a Windows Server demo VM.')
param deployWindowsVm bool = true

@description('Deploy an Ubuntu Linux demo VM.')
param deployLinuxVm bool = false

@description('Deploy Azure Files demo storage and file share.')
param deployAzureFiles bool = true

@description('Deploy optional Backup vault for newer Azure Backup workloads.')
param deployBackupVault bool = true

@description('Create optional managed data disk for disk-backup walkthroughs.')
param deployDiskBackup bool = false

@description('Enable soft delete on backup vault resources where supported.')
param enableSoftDelete bool = true

@description('Set immutable vault to unlocked where supported. Do not lock in disposable demos unless cleanup is tested.')
param enableImmutableVault bool = false

@minValue(1)
@maxValue(30)
@description('Short demo retention in days.')
param retentionDays int = 7

@allowed([
  'LRS'
  'GRS'
  'ZRS'
])
@description('Storage redundancy choice for demo resources.')
param storageRedundancy string = 'LRS'

@description('Optional email receiver for backup alerts. Leave empty to skip action group email receiver.')
param alertEmail string = ''

@description('Optional principal ID assigned Backup Contributor on the Recovery Services vault.')
param backupAdminPrincipalId string = ''

@description('Optional principal ID assigned Backup Operator on the Recovery Services vault.')
param restoreOperatorPrincipalId string = ''

@description('Optional principal ID assigned Backup Reader on the Recovery Services vault.')
param securityReviewerPrincipalId string = ''

var normalizedEnvironment = toLower(replace(environmentName, '-', ''))
var coreResourceGroupName = 'rg-backup-demo-core'
var protectionResourceGroupName = 'rg-backup-demo-protection'
var opsResourceGroupName = 'rg-backup-demo-ops'
var tags = {
  Environment: 'Demo'
  Workload: 'AzureBackup'
  Owner: owner
  CostCenter: 'Demo'
  AutoDeleteAfter: autoDeleteAfter
  SpecDrivenDeployment: 'AzureBackupDemo'
}
var storageSkuName = 'Standard_${storageRedundancy}'
var storageAccountName = take('st${normalizedEnvironment}${uniqueString(subscription().id, environmentName)}', 24)
var recoveryServicesVaultName = 'rsv-backup-demo-${regionCode}'
var backupVaultName = 'bv-backup-demo-${regionCode}'
var logAnalyticsName = 'law-backup-demo-${regionCode}'

resource coreResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: coreResourceGroupName
  location: location
  tags: tags
}

resource protectionResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: protectionResourceGroupName
  location: location
  tags: tags
}

resource opsResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: opsResourceGroupName
  location: location
  tags: tags
}

module monitoring './modules/monitoring.bicep' = {
  scope: opsResourceGroup
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    alertEmail: alertEmail
    tags: tags
  }
}

module storage './modules/storage.bicep' = {
  scope: coreResourceGroup
  params: {
    location: location
    storageAccountName: storageAccountName
    storageSkuName: storageSkuName
    deployAzureFiles: deployAzureFiles
    tags: tags
  }
}

module workloadVm './modules/vm.bicep' = {
  scope: coreResourceGroup
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    deployWindowsVm: deployWindowsVm
    deployLinuxVm: deployLinuxVm
    deployDiskBackup: deployDiskBackup
    tags: tags
  }
}

module recoveryServicesVault './modules/recovery-services-vault.bicep' = {
  scope: protectionResourceGroup
  params: {
    location: location
    vaultName: recoveryServicesVaultName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    enableSoftDelete: enableSoftDelete
    enableImmutableVault: enableImmutableVault
    retentionDays: retentionDays
    tags: tags
  }
}

module backupVault './modules/backup-vault.bicep' = if (deployBackupVault) {
  scope: protectionResourceGroup
  params: {
    location: location
    backupVaultName: backupVaultName
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    storageRedundancy: storageRedundancy
    enableSoftDelete: enableSoftDelete
    tags: tags
  }
}

module rbac './modules/rbac.bicep' = {
  scope: protectionResourceGroup
  params: {
    recoveryServicesVaultName: recoveryServicesVaultName
    backupVaultName: backupVaultName
    deployBackupVault: deployBackupVault
    backupAdminPrincipalId: backupAdminPrincipalId
    restoreOperatorPrincipalId: restoreOperatorPrincipalId
    securityReviewerPrincipalId: securityReviewerPrincipalId
  }
  dependsOn: [
    recoveryServicesVault
    backupVault
  ]
}

@description('Core resource group name.')
output coreResourceGroupName string = coreResourceGroup.name

@description('Protection resource group name.')
output protectionResourceGroupName string = protectionResourceGroup.name

@description('Operations resource group name.')
output opsResourceGroupName string = opsResourceGroup.name

@description('Recovery Services vault name.')
output recoveryServicesVaultName string = recoveryServicesVault.outputs.vaultName

@description('Optional Backup vault name.')
output backupVaultName string = backupVault.?outputs.?backupVaultName ?? ''

@description('Demo storage account name.')
output storageAccountName string = storage.outputs.storageAccountName

@description('Windows demo VM name, when deployed.')
output windowsVmName string = workloadVm.outputs.windowsVmName

@description('Linux demo VM name, when deployed.')
output linuxVmName string = workloadVm.outputs.linuxVmName
