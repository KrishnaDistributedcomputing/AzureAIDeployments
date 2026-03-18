// ============================================================================
// Pattern 1: Centralized AI Platform (Hub AI Pattern)
// ============================================================================
// A single-region shared AI platform hosted in the Platform Landing Zone (Hub)
// consumed by multiple spokes via VNet peering and private endpoints.
//
// Hub (Platform LZ): Azure OpenAI, AML, AI Search, ADLS Gen2, Key Vault
// Spokes (App LZ): Applications (AKS / App Service) with private access
//
// Use Cases: Enterprise-wide copilots, shared AI services, controlled cost
// ============================================================================

targetScope = 'resourceGroup'

// --- Parameters ---

@description('Azure region for all resources')
param location string = 'canadacentral'

@description('Environment name')
param environmentName ('dev' | 'staging' | 'prod') = 'dev'

@description('Base name for resource naming')
param baseName string = 'hubai'

@description('Tags applied to all resources')
param tags object = {
  pattern: 'centralized-hub-ai'
  environment: environmentName
}

@description('Azure OpenAI model deployments')
param openAiDeployments array = [
  {
    name: 'gpt-4o'
    modelName: 'gpt-4o'
    modelVersion: '2024-08-06'
    capacity: 30
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

@description('Hub VNet address space')
param hubVnetAddressPrefix string = '10.0.0.0/16'

@description('Number of spoke VNets to create')
@minValue(1)
@maxValue(10)
param spokeCount int = 2

@description('Spoke VNet address prefixes (one per spoke)')
param spokeVnetAddressPrefixes string[] = [
  '10.1.0.0/16'
  '10.2.0.0/16'
]

// --- Variables ---

var resourcePrefix = '${baseName}-${environmentName}'
var hubSubnets = [
  { name: 'ai-services', addressPrefix: '10.0.1.0/24', privateEndpointNetworkPolicies: 'Disabled' }
  { name: 'compute', addressPrefix: '10.0.2.0/24' }
  { name: 'data', addressPrefix: '10.0.3.0/24', privateEndpointNetworkPolicies: 'Disabled' }
  { name: 'management', addressPrefix: '10.0.4.0/24' }
]

// --- Monitoring (Foundation) ---

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
    appInsightsName: '${resourcePrefix}-ai'
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// --- Hub Networking ---

module hubNsg '../../modules/networking/nsg.bicep' = {
  params: {
    location: location
    nsgName: '${resourcePrefix}-hub-nsg'
    tags: tags
    securityRules: [
      {
        name: 'DenyAllInbound'
        priority: 4096
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '*'
      }
    ]
  }
}

module hubVnet '../../modules/networking/vnet.bicep' = {
  params: {
    location: location
    vnetName: '${resourcePrefix}-hub-vnet'
    addressPrefix: hubVnetAddressPrefix
    subnets: hubSubnets
    tags: tags
  }
}

// --- Spoke VNets + Peering ---

module spokeVnets '../../modules/networking/vnet.bicep' = [
  for i in range(0, spokeCount): {
    params: {
      location: location
      vnetName: '${resourcePrefix}-spoke-${i + 1}-vnet'
      addressPrefix: spokeVnetAddressPrefixes[i]
      subnets: [
        {
          name: 'app-compute'
          addressPrefix: cidrSubnet(spokeVnetAddressPrefixes[i], 24, 1)
        }
        {
          name: 'private-endpoints'
          addressPrefix: cidrSubnet(spokeVnetAddressPrefixes[i], 24, 2)
          privateEndpointNetworkPolicies: 'Disabled'
        }
      ]
      tags: tags
    }
  }
]

// Hub-to-Spoke peering
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = [
  for i in range(0, spokeCount): {
    name: '${resourcePrefix}-hub-vnet/hub-to-spoke-${i + 1}'
    properties: {
      remoteVirtualNetwork: {
        id: spokeVnets[i].outputs.id
      }
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      allowGatewayTransit: false
    }
    dependsOn: [hubVnet]
  }
]

// Spoke-to-Hub peering
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = [
  for i in range(0, spokeCount): {
    name: '${resourcePrefix}-spoke-${i + 1}-vnet/spoke-${i + 1}-to-hub'
    properties: {
      remoteVirtualNetwork: {
        id: hubVnet.outputs.id
      }
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: false
      useRemoteGateways: false
    }
    dependsOn: [spokeVnets]
  }
]

// --- Private DNS Zones ---

var privateDnsZones = [
  'privatelink.openai.azure.com'
  'privatelink.search.windows.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.blob.core.windows.net'
  'privatelink.dfs.core.windows.net'
  'privatelink.api.azureml.ms'
]

module dnsZones '../../modules/networking/privateDnsZone.bicep' = [
  for zone in privateDnsZones: {
    params: {
      zoneName: zone
      vnetId: hubVnet.outputs.id
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

// --- Storage ---

module adlsGen2 '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: replace('${baseName}${environmentName}adls', '-', '')
    isHnsEnabled: true
    containerNames: ['raw', 'processed', 'models', 'embeddings']
    tags: tags
  }
}

// --- AI Services (Hub) ---

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

module machineLearning '../../modules/ai/machineLearning.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-aml'
    keyVaultId: keyVault.outputs.id
    storageAccountId: adlsGen2.outputs.id
    applicationInsightsId: appInsights.outputs.id
    tags: tags
  }
}

// --- Private Endpoints for Hub AI Services ---

module openAiPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-openai-pe'
    subnetId: hubVnet.outputs.subnets[0].id // ai-services subnet
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
    subnetId: hubVnet.outputs.subnets[0].id
    privateLinkServiceId: aiSearch.outputs.id
    groupIds: ['searchService']
    privateDnsZoneId: dnsZones[1].outputs.id
    tags: tags
  }
}

module keyVaultPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-kv-pe'
    subnetId: hubVnet.outputs.subnets[0].id
    privateLinkServiceId: keyVault.outputs.id
    groupIds: ['vault']
    privateDnsZoneId: dnsZones[2].outputs.id
    tags: tags
  }
}

module storageBlobPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-blob-pe'
    subnetId: hubVnet.outputs.subnets[2].id // data subnet
    privateLinkServiceId: adlsGen2.outputs.id
    groupIds: ['blob']
    privateDnsZoneId: dnsZones[3].outputs.id
    tags: tags
  }
}

// --- Outputs ---

@description('Hub VNet ID')
output hubVnetId string = hubVnet.outputs.id

@description('Azure OpenAI endpoint')
output openAiEndpoint string = openAi.outputs.endpoint

@description('AI Search service name')
output aiSearchName string = aiSearch.outputs.name

@description('AML workspace name')
output amlWorkspaceName string = machineLearning.outputs.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.outputs.vaultUri

@description('Spoke VNet IDs')
output spokeVnetIds array = [for i in range(0, spokeCount): spokeVnets[i].outputs.id]
