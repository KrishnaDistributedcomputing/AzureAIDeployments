// Azure Monitor (Log Analytics Workspace) - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-09-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'monitoring-services'
}

var workspaceName = 'log-${environment}-${uniqueString(resourceGroup().id)}'
var applicationInsightsName = 'appi-${environment}-${uniqueString(resourceGroup().id)}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@${apiVersion}' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
      legacy: 0
      immediatePurgeDataOn30Days: true
    }
    workspaceCapping: {
      dailyQuotaGb: 10
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-11-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output applicationInsightsId string = applicationInsights.id
output applicationInsightsKey string = applicationInsights.properties.InstrumentationKey
