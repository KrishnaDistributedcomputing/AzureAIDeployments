// ============================================================================
// Pattern 3: Hybrid Pattern (Central AI + Spoke Inference)
// ============================================================================
// Core AI services are centralized in the Hub. Inference, customization,
// and RAG components are deployed in application spokes.
//
// Hub: Azure OpenAI (base models), Model Registry (AML)
// Spoke: Fine-tuned models, Vector DB (AI Search), App compute (AKS/App Svc)
//
// Use Cases: CSI-style vertical apps, RAG applications, controlled model reuse
// ============================================================================

targetScope = 'resourceGroup'

// --- Parameters ---

@description('Azure region')
param location string = 'canadacentral'

@description('Environment name')
param environmentName ('dev' | 'staging' | 'prod') = 'dev'

@description('Base name prefix')
param baseName string = 'hybrid'

@description('Spoke workload name')
param spokeWorkloadName string = 'app1'

@description('Tags')
param tags object = {
  pattern: 'hybrid-central-spoke'
  environment: environmentName
}

@description('Hub OpenAI model deployments (base models)')
param hubOpenAiDeployments array = [
  {
    name: 'gpt-4o'
    modelName: 'gpt-4o'
    modelVersion: '2024-08-06'
    capacity: 50
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

@description('Hub VNet address prefix')
param hubVnetAddressPrefix string = '10.0.0.0/16'

@description('Spoke VNet address prefix')
param spokeVnetAddressPrefix string = '10.1.0.0/16'

@description('Whether to deploy App Service (true) or AKS (false) in spoke')
param useAppService bool = true

// --- Variables ---

var hubPrefix = '${baseName}-hub-${environmentName}'
var spokePrefix = '${baseName}-${spokeWorkloadName}-${environmentName}'

// --- Monitoring ---

module logAnalytics '../../modules/monitoring/logAnalytics.bicep' = {
  params: {
    location: location
    workspaceName: '${baseName}-${environmentName}-law'
    tags: tags
  }
}

module appInsights '../../modules/monitoring/appInsights.bicep' = {
  params: {
    location: location
    appInsightsName: '${baseName}-${environmentName}-ai'
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// ===========================
// HUB LAYER
// ===========================

module hubVnet '../../modules/networking/vnet.bicep' = {
  params: {
    location: location
    vnetName: '${hubPrefix}-vnet'
    addressPrefix: hubVnetAddressPrefix
    subnets: [
      { name: 'ai-services', addressPrefix: '10.0.1.0/24', privateEndpointNetworkPolicies: 'Disabled' }
      { name: 'ml-workspace', addressPrefix: '10.0.2.0/24', privateEndpointNetworkPolicies: 'Disabled' }
      { name: 'management', addressPrefix: '10.0.3.0/24' }
    ]
    tags: tags
  }
}

module hubKeyVault '../../modules/security/keyVault.bicep' = {
  params: {
    location: location
    keyVaultName: '${hubPrefix}-kv'
    tags: tags
  }
}

module hubStorage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: replace('${baseName}hub${environmentName}sa', '-', '')
    containerNames: ['models', 'datasets', 'artifacts']
    tags: tags
  }
}

// Hub: Azure OpenAI (base models shared across spokes)
module hubOpenAi '../../modules/ai/openai.bicep' = {
  params: {
    location: location
    openAiName: '${hubPrefix}-openai'
    deployments: hubOpenAiDeployments
    tags: tags
  }
}

// Hub: Azure Machine Learning (model registry + training)
module hubMachineLearning '../../modules/ai/machineLearning.bicep' = {
  params: {
    location: location
    workspaceName: '${hubPrefix}-aml'
    keyVaultId: hubKeyVault.outputs.id
    storageAccountId: hubStorage.outputs.id
    applicationInsightsId: appInsights.outputs.id
    tags: tags
  }
}

// Hub DNS Zones
var hubDnsZones = [
  'privatelink.openai.azure.com'
  'privatelink.api.azureml.ms'
  'privatelink.vaultcore.azure.net'
  'privatelink.blob.core.windows.net'
  'privatelink.search.windows.net'
]

module dnsZones '../../modules/networking/privateDnsZone.bicep' = [
  for zone in hubDnsZones: {
    params: {
      zoneName: zone
      vnetId: hubVnet.outputs.id
      tags: tags
    }
  }
]

// Hub Private Endpoints
module hubOpenAiPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${hubPrefix}-openai-pe'
    subnetId: hubVnet.outputs.subnets[0].id
    privateLinkServiceId: hubOpenAi.outputs.id
    groupIds: ['account']
    privateDnsZoneId: dnsZones[0].outputs.id
    tags: tags
  }
}

// ===========================
// SPOKE LAYER (Inference + RAG)
// ===========================

module spokeVnet '../../modules/networking/vnet.bicep' = {
  params: {
    location: location
    vnetName: '${spokePrefix}-vnet'
    addressPrefix: spokeVnetAddressPrefix
    subnets: [
      { name: 'app-compute', addressPrefix: '10.1.1.0/24' }
      { name: 'private-endpoints', addressPrefix: '10.1.2.0/24', privateEndpointNetworkPolicies: 'Disabled' }
      {
        name: 'app-service-integration'
        addressPrefix: '10.1.3.0/24'
        delegations: ['Microsoft.Web/serverFarms']
      }
    ]
    tags: tags
  }
}

// Spoke: AI Search (vector DB for RAG)
module spokeAiSearch '../../modules/ai/aiSearch.bicep' = {
  params: {
    location: location
    searchName: '${spokePrefix}-search'
    sku: 'standard'
    semanticSearch: 'standard'
    tags: tags
  }
}

// Spoke: Storage for workload-specific data
module spokeStorage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: replace('${baseName}${spokeWorkloadName}${environmentName}sa', '-', '')
    containerNames: ['documents', 'embeddings', 'cache']
    tags: tags
  }
}

// Spoke: App Service OR AKS for inference
module spokeAppService '../../modules/compute/appService.bicep' = if (useAppService) {
  params: {
    location: location
    appServicePlanName: '${spokePrefix}-asp'
    webAppName: '${spokePrefix}-app'
    vnetIntegrationSubnetId: spokeVnet.outputs.subnets[2].id
    appSettings: [
      { name: 'AZURE_OPENAI_ENDPOINT', value: hubOpenAi.outputs.endpoint }
      { name: 'AZURE_SEARCH_SERVICE', value: spokeAiSearch.outputs.name }
    ]
    tags: tags
  }
}

module spokeAks '../../modules/compute/aks.bicep' = if (!useAppService) {
  params: {
    location: location
    clusterName: '${spokePrefix}-aks'
    subnetId: spokeVnet.outputs.subnets[0].id
    systemNodeCount: 3
    tags: tags
  }
}

// VNet peering: Hub <-> Spoke
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: '${hubPrefix}-vnet/hub-to-${spokeWorkloadName}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet.outputs.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
  dependsOn: [hubVnet]
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: '${spokePrefix}-vnet/${spokeWorkloadName}-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.outputs.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
  }
  dependsOn: [spokeVnet]
}

// Spoke Private Endpoints
module spokeSearchPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${spokePrefix}-search-pe'
    subnetId: spokeVnet.outputs.subnets[1].id
    privateLinkServiceId: spokeAiSearch.outputs.id
    groupIds: ['searchService']
    privateDnsZoneId: dnsZones[4].outputs.id
    tags: tags
  }
}

// --- Outputs ---

@description('Hub OpenAI endpoint (shared base models)')
output hubOpenAiEndpoint string = hubOpenAi.outputs.endpoint

@description('Hub AML workspace')
output hubAmlWorkspace string = hubMachineLearning.outputs.name

@description('Spoke AI Search name')
output spokeAiSearchName string = spokeAiSearch.outputs.name

@description('Spoke VNet ID')
output spokeVnetId string = spokeVnet.outputs.id

@description('Hub VNet ID')
output hubVnetId string = hubVnet.outputs.id
