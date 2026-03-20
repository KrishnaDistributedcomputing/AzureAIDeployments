// Azure AI Search - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-06-01-preview'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'data-services'
}

var searchServiceName = 'search-${environment}-${uniqueString(resourceGroup().id)}'

resource searchService 'Microsoft.Search/searchServices@${apiVersion}' = {
  name: searchServiceName
  location: location
  sku: {
    name: 'standard'
  }
  kind: 'default'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: 3
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'None'
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    semanticConfiguration: null
  }
}

// Semantic Configuration for Hybrid Search
resource semanticConfig 'Microsoft.Search/searchServices/semanticConfigs@${apiVersion}' = {
  parent: searchService
  name: 'my-semantic-config'
  properties: {
    description: 'Semantic configuration for hybrid search'
    prioritizedFields: {
      titleField: {
        fieldName: 'title'
      }
      contentFields: [{
        fieldName: 'content'
      }]
      keywordsFields: [{
        fieldName: 'keywords'
      }]
    }
  }
}

output searchServiceId string = searchService.id
output searchServiceEndpoint string = 'https://${searchService.name}.search.windows.net'
output searchServiceName string = searchService.name
