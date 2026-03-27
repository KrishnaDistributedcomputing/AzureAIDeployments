// App Service - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-12-01'
param appServicePlanSkuName string = 'P1v3'
param appServicePlanSkuTier string = 'PremiumV3'
param appRuntimeStack string = 'PYTHON|3.11'
param alwaysOn bool = true
param ftpsState string = 'Disabled'
param httpsOnly bool = true
param minimumTlsVersion string = '1.2'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'compute-services'
}

var planName = 'asp-${environment}-${uniqueString(resourceGroup().id)}'
var webAppName = 'appsvc-${environment}-${uniqueString(resourceGroup().id)}'
var insightsName = 'appi-${environment}-${uniqueString(resourceGroup().id)}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: insightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: ''
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@${apiVersion}' = {
  name: planName
  location: location
  tags: tags
  sku: {
    name: appServicePlanSkuName
    tier: appServicePlanSkuTier
    size: appServicePlanSkuName
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
    zoneRedundant: false
  }
}

resource webApp 'Microsoft.Web/sites@${apiVersion}' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: httpsOnly
    siteConfig: {
      linuxFxVersion: appRuntimeStack
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      minTlsVersion: minimumTlsVersion
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
  }
}

resource stagingSlot 'Microsoft.Web/sites/slots@${apiVersion}' = {
  name: '${webApp.name}/staging'
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: httpsOnly
    siteConfig: {
      linuxFxVersion: appRuntimeStack
      alwaysOn: alwaysOn
      ftpsState: ftpsState
      minTlsVersion: minimumTlsVersion
    }
  }
}

output appServicePlanId string = appServicePlan.id
output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output stagingSlotId string = stagingSlot.id
