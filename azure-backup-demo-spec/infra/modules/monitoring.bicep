targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Log Analytics workspace name.')
param logAnalyticsName string

@description('Optional email receiver for backup alerts.')
param alertEmail string = ''

@description('Tags applied to resources.')
param tags object = {}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (!empty(alertEmail)) {
  name: 'ag-backup-demo'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'backupdemo'
    enabled: true
    emailReceivers: [
      {
        name: 'backup-demo-email'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

@description('Log Analytics workspace resource ID.')
output logAnalyticsWorkspaceId string = logAnalytics.id

@description('Optional action group resource ID.')
output actionGroupId string = !empty(alertEmail) ? actionGroup.id : ''
