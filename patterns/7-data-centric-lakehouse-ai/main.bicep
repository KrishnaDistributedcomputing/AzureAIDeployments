// ============================================================================
// Pattern 7: Data-Centric AI Pattern (Lakehouse + AI)
// ============================================================================
// AI tightly integrated with a single-region data platform.
// Combines a lakehouse architecture (ADLS + Databricks + Delta Lake)
// with Azure AI Search (vector layer) and Azure OpenAI (inference).
//
// Landing Zone: Data Landing Zone + App LZ integration
//
// Use Cases: RAG, Knowledge copilots, Analytics + AI combined workloads
// ============================================================================

targetScope = 'resourceGroup'

// --- Parameters ---

@description('Azure region')
param location string = 'canadacentral'

@description('Environment name')
param environmentName ('dev' | 'staging' | 'prod') = 'dev'

@description('Base name prefix')
param baseName string = 'datalake'

@description('Tags')
param tags object = {
  pattern: 'data-centric-lakehouse-ai'
  environment: environmentName
}

@description('OpenAI model deployments')
param openAiDeployments array = [
  {
    name: 'gpt-4o'
    modelName: 'gpt-4o'
    modelVersion: '2024-08-06'
    capacity: 40
    skuName: 'GlobalStandard'
  }
  {
    name: 'text-embedding-3-large'
    modelName: 'text-embedding-3-large'
    modelVersion: '1'
    capacity: 120
    skuName: 'Standard'
  }
]

@description('VNet address prefix')
param vnetAddressPrefix string = '10.40.0.0/16'

@description('Databricks pricing tier')
param databricksTier ('standard' | 'premium') = 'premium'

@description('Whether to deploy an App Service for serving the AI app')
param deployAppService bool = true

// --- Variables ---

var resourcePrefix = '${baseName}-${environmentName}'
var cleanPrefix = replace('${baseName}${environmentName}', '-', '')

// --- Monitoring ---

module logAnalytics '../../modules/monitoring/logAnalytics.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-law'
    retentionInDays: 90
    tags: tags
  }
}

module appInsights '../../modules/monitoring/appInsights.bicep' = {
  params: {
    location: location
    appInsightsName: '${resourcePrefix}-appinsights'
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// --- Networking ---

module vnet '../../modules/networking/vnet.bicep' = {
  params: {
    location: location
    vnetName: '${resourcePrefix}-vnet'
    addressPrefix: vnetAddressPrefix
    subnets: [
      {
        name: 'databricks-public'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 22, 0)
        delegations: ['Microsoft.Databricks/workspaces']
      }
      {
        name: 'databricks-private'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 22, 1)
        delegations: ['Microsoft.Databricks/workspaces']
      }
      {
        name: 'private-endpoints'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 8)
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: 'data-endpoints'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 9)
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: 'app-compute'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 10)
      }
      {
        name: 'app-service-integration'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 11)
        delegations: ['Microsoft.Web/serverFarms']
      }
    ]
    tags: tags
  }
}

// Private DNS Zones
var dnsZoneNames = [
  'privatelink.openai.azure.com'
  'privatelink.search.windows.net'
  'privatelink.blob.core.windows.net'
  'privatelink.dfs.core.windows.net'
  'privatelink.vaultcore.azure.net'
]

module dnsZones '../../modules/networking/privateDnsZone.bicep' = [
  for zone in dnsZoneNames: {
    params: {
      zoneName: zone
      vnetId: vnet.outputs.id
      tags: tags
    }
  }
]

// --- Security ---

module keyVault '../../modules/security/keyVault.bicep' = {
  params: {
    location: location
    keyVaultName: '${resourcePrefix}-kv'
    tags: tags
  }
}

// --- Data Lake Storage (Multi-Zone Architecture) ---

// Raw/Landing Zone
module rawStorage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: '${cleanPrefix}raw'
    isHnsEnabled: true
    containerNames: ['landing', 'raw', 'archive']
    tags: tags
  }
}

// Curated/Enriched Zone
module curatedStorage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: '${cleanPrefix}curated'
    isHnsEnabled: true
    containerNames: ['silver', 'gold', 'delta-tables']
    tags: tags
  }
}

// AI/Serving Zone
module aiStorage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: '${cleanPrefix}serving'
    isHnsEnabled: true
    containerNames: ['embeddings', 'vector-indexes', 'model-artifacts', 'documents']
    tags: tags
  }
}

// --- Databricks (Data Engineering + Feature Engineering) ---

module databricks '../../modules/data/databricks.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-dbw'
    pricingTier: databricksTier
    customVirtualNetworkId: vnet.outputs.id
    publicSubnetName: 'databricks-public'
    privateSubnetName: 'databricks-private'
    tags: tags
  }
}

// --- AI Services ---

module openAi '../../modules/ai/openai.bicep' = {
  params: {
    location: location
    openAiName: '${resourcePrefix}-openai'
    deployments: openAiDeployments
    tags: tags
  }
}

module aiSearch '../../modules/ai/aiSearch.bicep' = {
  params: {
    location: location
    searchName: '${resourcePrefix}-search'
    sku: 'standard'
    semanticSearch: 'standard'
    replicaCount: 2
    tags: tags
  }
}

// --- App Compute (Optional App Service for serving) ---

module appService '../../modules/compute/appService.bicep' = if (deployAppService) {
  params: {
    location: location
    appServicePlanName: '${resourcePrefix}-asp'
    webAppName: '${resourcePrefix}-app'
    vnetIntegrationSubnetId: vnet.outputs.subnets[5].id
    appSettings: [
      { name: 'AZURE_OPENAI_ENDPOINT', value: openAi.outputs.endpoint }
      { name: 'AZURE_SEARCH_SERVICE', value: aiSearch.outputs.name }
      { name: 'AZURE_STORAGE_RAW', value: rawStorage.outputs.name }
      { name: 'AZURE_STORAGE_CURATED', value: curatedStorage.outputs.name }
      { name: 'AZURE_STORAGE_SERVING', value: aiStorage.outputs.name }
    ]
    tags: tags
  }
}

// --- Private Endpoints ---

module openAiPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-openai-pe'
    subnetId: vnet.outputs.subnets[2].id
    privateLinkServiceId: openAi.outputs.id
    groupIds: ['account']
    privateDnsZoneId: dnsZones[0].outputs.id
    tags: tags
  }
}

module aiSearchPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-search-pe'
    subnetId: vnet.outputs.subnets[2].id
    privateLinkServiceId: aiSearch.outputs.id
    groupIds: ['searchService']
    privateDnsZoneId: dnsZones[1].outputs.id
    tags: tags
  }
}

module rawStorageBlobPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-raw-blob-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: rawStorage.outputs.id
    groupIds: ['blob']
    privateDnsZoneId: dnsZones[2].outputs.id
    tags: tags
  }
}

module rawStorageDfsPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-raw-dfs-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: rawStorage.outputs.id
    groupIds: ['dfs']
    privateDnsZoneId: dnsZones[3].outputs.id
    tags: tags
  }
}

module curatedStorageDfsPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-curated-dfs-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: curatedStorage.outputs.id
    groupIds: ['dfs']
    privateDnsZoneId: dnsZones[3].outputs.id
    tags: tags
  }
}

module aiStorageBlobPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-serving-blob-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: aiStorage.outputs.id
    groupIds: ['blob']
    privateDnsZoneId: dnsZones[2].outputs.id
    tags: tags
  }
}

module keyVaultPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-kv-pe'
    subnetId: vnet.outputs.subnets[2].id
    privateLinkServiceId: keyVault.outputs.id
    groupIds: ['vault']
    privateDnsZoneId: dnsZones[4].outputs.id
    tags: tags
  }
}

// --- Outputs ---

@description('Databricks workspace URL')
output databricksWorkspaceUrl string = databricks.outputs.workspaceUrl

@description('OpenAI endpoint')
output openAiEndpoint string = openAi.outputs.endpoint

@description('AI Search name')
output aiSearchName string = aiSearch.outputs.name

@description('Raw storage account')
output rawStorageName string = rawStorage.outputs.name

@description('Curated storage account')
output curatedStorageName string = curatedStorage.outputs.name

@description('AI serving storage account')
output aiStorageName string = aiStorage.outputs.name

@description('VNet ID')
output vnetId string = vnet.outputs.id
