// Azure Functions Module
// Deploys serverless compute for lightweight AI workloads

@description('Azure region')
param location string

@description('Function App name')
param functionAppName string

@description('App Service Plan name')
param appServicePlanName string

@description('Storage account name for Functions runtime')
param storageAccountName string

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Runtime stack')
param runtime ('python' | 'node' | 'dotnet-isolated') = 'python'

@description('Runtime version')
param runtimeVersion string = '3.11'

@description('App settings')
param appSettings appSettingPair[] = []

@description('Tags')
param tags object = {}

type appSettingPair = {
  name: string
  @secure()
  value: string
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

var baseSettings = [
  { name: 'AzureWebJobsStorage', value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}' }
  { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
  { name: 'FUNCTIONS_WORKER_RUNTIME', value: runtime }
]

var insightsSettings = !empty(appInsightsConnectionString)
  ? [{ name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }]
  : []

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: '${toUpper(runtime)}|${runtimeVersion}'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: union(baseSettings, insightsSettings, appSettings)
    }
  }
}

@description('Function App resource ID')
output id string = functionApp.id

@description('Function App default hostname')
output defaultHostName string = functionApp.properties.defaultHostName

@description('Function App principal ID')
output principalId string = functionApp.identity.principalId
