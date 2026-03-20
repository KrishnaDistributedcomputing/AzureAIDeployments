// API Management - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-09-01-preview'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'api-services'
}

var apimServiceName = 'apim-${environment}-${uniqueString(resourceGroup().id)}'
var publisherName = 'Organization'
var publisherEmail = 'admin@organization.com'

resource apiManagement 'Microsoft.ApiManagement/service@${apiVersion}' = {
  name: apimServiceName
  location: location
  tags: tags
  sku: {
    name: 'StandardV2'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
    notificationSenderEmail: 'noreply@microsoft.com'
    virtualNetworkType: 'None'
    apiVersionConstraint: {
      minApiVersion: '2021-01-01-preview'
    }
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: '${apimServiceName}.azure-api.net'
        negotiateClientCertificate: false
        defaultSslBinding: true
      }
    ]
  }
}

// Named Value for API Key
resource namedValue 'Microsoft.ApiManagement/service/namedValues@${apiVersion}' = {
  parent: apiManagement
  name: 'openai-api-key'
  properties: {
    displayName: 'OpenAI API Key'
    value: 'your-api-key-here'
    secret: true
  }
}

// API for GenAI Gateway
resource api 'Microsoft.ApiManagement/service/apis@${apiVersion}' = {
  parent: apiManagement
  name: 'openai-api'
  properties: {
    displayName: 'OpenAI API'
    apiRevision: '1'
    path: '/openai'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
    serviceUrl: 'https://your-openai.openai.azure.com/openai'
  }
}

output apiManagementId string = apiManagement.id
output apiManagementEndpoint string = 'https://${apimServiceName}.azure-api.net'
