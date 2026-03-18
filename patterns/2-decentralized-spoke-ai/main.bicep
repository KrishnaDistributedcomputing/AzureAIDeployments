// ============================================================================
// Pattern 2: Decentralized AI per Workload (Spoke AI Pattern)
// ============================================================================
// Each application has its own AI stack deployed inside its own landing zone.
// No dependency on a central AI hub. Full isolation per workload.
//
// Each Spoke LZ contains: Azure OpenAI, Storage, AI Search, Compute (AKS)
//
// Use Cases: Data isolation (PII, PCI, PHI), independent product teams,
//            high throughput workloads
// ============================================================================

targetScope = 'resourceGroup'

// --- Parameters ---

@description('Azure region')
param location string = 'canadacentral'

@description('Environment name')
param environmentName ('dev' | 'staging' | 'prod') = 'dev'

@description('Workload name (unique per spoke)')
param workloadName string

@description('Tags')
param tags object = {
  pattern: 'decentralized-spoke-ai'
  environment: environmentName
  workload: workloadName
}

@description('OpenAI model deployments for this workload')
param openAiDeployments array = [
  {
    name: 'gpt-4o'
    modelName: 'gpt-4o'
    modelVersion: '2024-08-06'
    capacity: 20
    skuName: 'GlobalStandard'
  }
]

@description('VNet address prefix')
param vnetAddressPrefix string = '10.10.0.0/16'

@description('AKS system node count')
param aksSystemNodeCount int = 3

@description('AKS AI/GPU node count (0 to skip)')
param aksAiNodeCount int = 0

// --- Variables ---

var resourcePrefix = '${workloadName}-${environmentName}'

// --- Monitoring ---

module logAnalytics '../../modules/monitoring/logAnalytics.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-law'
    tags: tags
  }
}

module appInsights '../../modules/monitoring/appInsights.bicep' = {
  params: {
    location: location
    appInsightsName: '${resourcePrefix}-ai'
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// --- Networking ---

module nsg '../../modules/networking/nsg.bicep' = {
  params: {
    location: location
    nsgName: '${resourcePrefix}-nsg'
    tags: tags
  }
}

module vnet '../../modules/networking/vnet.bicep' = {
  params: {
    location: location
    vnetName: '${resourcePrefix}-vnet'
    addressPrefix: vnetAddressPrefix
    subnets: [
      {
        name: 'aks-nodes'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 20, 0)
        nsgId: nsg.outputs.id
      }
      {
        name: 'private-endpoints'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 16)
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: 'data'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 17)
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
    tags: tags
  }
}

// --- Private DNS Zones ---

var dnsZoneNames = [
  'privatelink.openai.azure.com'
  'privatelink.search.windows.net'
  'privatelink.blob.core.windows.net'
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

// --- Storage (Workload-Owned) ---

module storage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: replace('${workloadName}${environmentName}sa', '-', '')
    isHnsEnabled: true
    containerNames: ['data', 'embeddings', 'models']
    tags: tags
  }
}

// --- AI Services (Workload-Owned) ---

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
    tags: tags
  }
}

// --- Compute (Workload-Owned) ---

module aks '../../modules/compute/aks.bicep' = {
  params: {
    location: location
    clusterName: '${resourcePrefix}-aks'
    subnetId: vnet.outputs.subnets[0].id // aks-nodes subnet
    systemNodeCount: aksSystemNodeCount
    aiNodeCount: aksAiNodeCount
    tags: tags
  }
}

// --- Private Endpoints ---

module openAiPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-openai-pe'
    subnetId: vnet.outputs.subnets[1].id
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
    subnetId: vnet.outputs.subnets[1].id
    privateLinkServiceId: aiSearch.outputs.id
    groupIds: ['searchService']
    privateDnsZoneId: dnsZones[1].outputs.id
    tags: tags
  }
}

module storagePe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-blob-pe'
    subnetId: vnet.outputs.subnets[2].id
    privateLinkServiceId: storage.outputs.id
    groupIds: ['blob']
    privateDnsZoneId: dnsZones[2].outputs.id
    tags: tags
  }
}

module keyVaultPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-kv-pe'
    subnetId: vnet.outputs.subnets[1].id
    privateLinkServiceId: keyVault.outputs.id
    groupIds: ['vault']
    privateDnsZoneId: dnsZones[3].outputs.id
    tags: tags
  }
}

// --- Outputs ---

@description('Workload VNet ID')
output vnetId string = vnet.outputs.id

@description('Azure OpenAI endpoint')
output openAiEndpoint string = openAi.outputs.endpoint

@description('AI Search name')
output aiSearchName string = aiSearch.outputs.name

@description('AKS cluster name')
output aksClusterName string = aks.outputs.name

@description('Storage account name')
output storageAccountName string = storage.outputs.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.outputs.vaultUri
