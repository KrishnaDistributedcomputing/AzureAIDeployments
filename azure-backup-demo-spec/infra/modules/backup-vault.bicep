targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Backup vault name.')
param backupVaultName string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

@allowed([
  'LRS'
  'GRS'
  'ZRS'
])
@description('Backup vault redundancy posture.')
param storageRedundancy string = 'LRS'

@description('Enable soft delete where supported.')
param enableSoftDelete bool = true

@description('Tags applied to resources.')
param tags object = {}

var datastoreRedundancy = storageRedundancy == 'ZRS' ? 'ZoneRedundant' : storageRedundancy == 'GRS' ? 'GeoRedundant' : 'LocallyRedundant'

resource backupVault 'Microsoft.DataProtection/backupVaults@2024-04-01' = {
  name: backupVaultName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: datastoreRedundancy
      }
    ]
    securitySettings: {
      softDeleteSettings: {
        state: enableSoftDelete ? 'On' : 'Off'
      }
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: backupVault
  name: 'diag-backup-vault-demo'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'CoreBackup'
        enabled: true
      }
      {
        category: 'AddonAzureBackupJobs'
        enabled: true
      }
      {
        category: 'AddonAzureBackupAlerts'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('Backup vault name.')
output backupVaultName string = backupVault.name

@description('Backup vault resource ID.')
output backupVaultId string = backupVault.id
