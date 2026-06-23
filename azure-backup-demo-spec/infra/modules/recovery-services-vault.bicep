targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Recovery Services vault name.')
param vaultName string

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

@description('Enable soft delete where supported.')
param enableSoftDelete bool = true

@description('Configure immutable vault as unlocked where supported.')
param enableImmutableVault bool = false

@minValue(1)
@maxValue(30)
@description('Daily recovery point retention in days.')
param retentionDays int = 7

@description('Tags applied to resources.')
param tags object = {}

var backupTime = '2026-01-01T22:00:00Z'

resource vault 'Microsoft.RecoveryServices/vaults@2024-10-01' = {
  name: vaultName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    securitySettings: {
      softDeleteSettings: {
        softDeleteState: enableSoftDelete ? 'Enabled' : 'Disabled'
      }
      immutabilitySettings: {
        state: enableImmutableVault ? 'Unlocked' : 'Disabled'
      }
    }
  }
}

resource vmBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01' = {
  parent: vault
  name: 'pol-vm-daily-demo'
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
    instantRpRetentionRangeInDays: 2
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes: [
          backupTime
        ]
      }
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          backupTime
        ]
        retentionDuration: {
          count: retentionDays
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

resource azureFilesPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01' = {
  parent: vault
  name: 'pol-files-daily-demo'
  properties: {
    backupManagementType: 'AzureStorage'
    workLoadType: 'AzureFileShare'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        backupTime
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          backupTime
        ]
        retentionDuration: {
          count: retentionDays
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: vault
  name: 'diag-backup-demo'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AzureBackupReport'
        enabled: true
      }
      {
        category: 'CoreAzureBackup'
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

@description('Recovery Services vault name.')
output vaultName string = vault.name

@description('Recovery Services vault resource ID.')
output vaultId string = vault.id

@description('VM backup policy name.')
output vmBackupPolicyName string = vmBackupPolicy.name

@description('Azure Files backup policy name.')
output azureFilesPolicyName string = azureFilesPolicy.name
