// App Service Module
// Deploys App Service Plan + Web App for AI applications

@description('Azure region')
param location string

@description('App Service Plan name')
param appServicePlanName string

@description('Web App name')
param webAppName string

@description('SKU for the App Service Plan')
param skuName string = 'P1v3'

@description('Runtime stack')
param linuxFxVersion string = 'PYTHON|3.11'

@description('Whether to enable VNet integration')
param vnetIntegrationSubnetId string = ''

@description('App settings')
param appSettings appSettingPair[] = []

@description('Tags')
param tags object = {}

type appSettingPair = {
  name: string
  @secure()
  value: string
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: !empty(vnetIntegrationSubnetId) ? vnetIntegrationSubnetId : null
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: appSettings
    }
  }
}

@description('Web App resource ID')
output id string = webApp.id

@description('Web App default hostname')
output defaultHostName string = webApp.properties.defaultHostName

@description('Web App principal ID')
output principalId string = webApp.identity.principalId
