// Application Insights Module

@description('Azure region')
param location string

@description('Application Insights name')
param appInsightsName string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Application type')
param applicationType string = 'web'

@description('Tags')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: applicationType
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

@description('Application Insights resource ID')
output id string = appInsights.id

@description('Application Insights instrumentation key')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('Application Insights connection string')
output connectionString string = appInsights.properties.ConnectionString
