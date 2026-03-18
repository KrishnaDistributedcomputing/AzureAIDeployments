// Log Analytics Workspace Module

@description('Azure region')
param location string

@description('Workspace name')
param workspaceName string

@description('SKU')
param skuName string = 'PerGB2018'

@description('Retention in days')
param retentionInDays int = 90

@description('Tags')
param tags object = {}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
  }
}

@description('Log Analytics workspace resource ID')
output id string = logAnalytics.id

@description('Log Analytics workspace name')
output name string = logAnalytics.name

@description('Log Analytics workspace ID (customer ID)')
output customerId string = logAnalytics.properties.customerId
