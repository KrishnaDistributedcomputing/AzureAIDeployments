// Azure AI Search Module
// Deploys Azure AI Search (formerly Cognitive Search)

@description('Azure region')
param location string

@description('Search service name')
param searchName string

@description('SKU')
param sku ('free' | 'basic' | 'standard' | 'standard2' | 'standard3' | 'storage_optimized_l1' | 'storage_optimized_l2') = 'standard'

@description('Replica count')
param replicaCount int = 1

@description('Partition count')
param partitionCount int = 1

@description('Whether to disable public network access')
param publicNetworkAccess ('enabled' | 'disabled') = 'enabled'

@description('Semantic search tier')
param semanticSearch ('disabled' | 'free' | 'standard') = 'standard'

@description('Tags')
param tags object = {}

resource search 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: searchName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    publicNetworkAccess: publicNetworkAccess
    semanticSearch: semanticSearch
    hostingMode: 'default'
  }
}

@description('Search service resource ID')
output id string = search.id

@description('Search service name')
output name string = search.name
