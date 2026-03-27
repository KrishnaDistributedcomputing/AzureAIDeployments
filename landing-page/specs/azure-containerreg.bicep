// Azure Container Registry - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-11-01-preview'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'container-services'
}

var registryName = 'acr${environment}${uniqueString(resourceGroup().id)}'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@${apiVersion}' = {
  name: registryName
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: false  // ✓ REQUIRED: Use managed identities for authentication
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      quarantinePolicy: {
        status: 'enabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 30
        status: 'enabled'
      }
    }
    encryption: {
      status: 'enabled'
      keyVaultProperties: null
    }
  }
}

// Webhook for notifications
resource webhook 'Microsoft.ContainerRegistry/registries/webhooks@${apiVersion}' = {
  parent: containerRegistry
  name: 'deployment-webhook'
  location: location
  properties: {
    actions: [
      'push'
      'delete'
    ]
    serviceUri: 'https://your-webhook-endpoint.com'
    customHeaders: {
      'X-Custom-Header': 'value'
    }
    status: 'enabled'
    scope: ''
  }
}

output registryId string = containerRegistry.id
output loginServer string = containerRegistry.properties.loginServer
output registryName string = containerRegistry.name
