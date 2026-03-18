// ============================================================================
// Pattern 6: Secure AI Pattern (Private AI / Zero Trust)
// ============================================================================
// AI deployed in a fully private, single-region network boundary.
// All services behind private endpoints, no public access, Azure Firewall,
// centralized logging, and Defender for Cloud.
//
// Platform LZ enforces: Deny public access policies, Defender, central logging
//
// Use Cases: Canadian data residency, financial/healthcare, regulated customers
// ============================================================================

targetScope = 'resourceGroup'

// --- Parameters ---

@description('Azure region')
param location string = 'canadacentral'

@description('Environment name')
param environmentName ('dev' | 'staging' | 'prod') = 'dev'

@description('Base name prefix')
param baseName string = 'secureai'

@description('Tags')
param tags object = {
  pattern: 'secure-private-ai'
  environment: environmentName
  compliance: 'zero-trust'
}

@description('OpenAI model deployments')
param openAiDeployments array = [
  {
    name: 'gpt-4o'
    modelName: 'gpt-4o'
    modelVersion: '2024-08-06'
    capacity: 30
    skuName: 'Standard'
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
param vnetAddressPrefix string = '10.30.0.0/16'

@description('AKS system node count')
param aksSystemNodeCount int = 3

@description('Azure Firewall SKU tier')
param firewallSkuTier ('Standard' | 'Premium') = 'Premium'

// --- Variables ---

var resourcePrefix = '${baseName}-${environmentName}'
var cleanPrefix = replace('${baseName}${environmentName}', '-', '')

// --- Monitoring (Centralized Logging) ---

module logAnalytics '../../modules/monitoring/logAnalytics.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-law'
    retentionInDays: 365 // Extended retention for compliance
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

// --- Network Security Groups ---

module aiSubnetNsg '../../modules/networking/nsg.bicep' = {
  params: {
    location: location
    nsgName: '${resourcePrefix}-ai-nsg'
    tags: tags
    securityRules: [
      {
        name: 'AllowVNetInbound'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: '*'
        sourceAddressPrefix: 'VirtualNetwork'
        sourcePortRange: '*'
        destinationAddressPrefix: 'VirtualNetwork'
        destinationPortRange: '*'
      }
      {
        name: 'DenyInternetInbound'
        priority: 4000
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourceAddressPrefix: 'Internet'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '*'
      }
      {
        name: 'DenyAllOutboundInternet'
        priority: 4000
        direction: 'Outbound'
        access: 'Deny'
        protocol: '*'
        sourceAddressPrefix: '*'
        sourcePortRange: '*'
        destinationAddressPrefix: 'Internet'
        destinationPortRange: '*'
      }
    ]
  }
}

module aksSubnetNsg '../../modules/networking/nsg.bicep' = {
  params: {
    location: location
    nsgName: '${resourcePrefix}-aks-nsg'
    tags: tags
    securityRules: [
      {
        name: 'AllowVNetInbound'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: '*'
        sourceAddressPrefix: 'VirtualNetwork'
        sourcePortRange: '*'
        destinationAddressPrefix: 'VirtualNetwork'
        destinationPortRange: '*'
      }
      {
        name: 'AllowAzureLoadBalancer'
        priority: 200
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: 'AzureLoadBalancer'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '*'
      }
      {
        name: 'DenyInternetInbound'
        priority: 4000
        direction: 'Inbound'
        access: 'Deny'
        protocol: '*'
        sourceAddressPrefix: 'Internet'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '*'
      }
    ]
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
        name: 'AzureFirewallSubnet'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 26, 0)
      }
      {
        name: 'aks-nodes'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 20, 1)
        nsgId: aksSubnetNsg.outputs.id
      }
      {
        name: 'private-endpoints'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 32)
        nsgId: aiSubnetNsg.outputs.id
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: 'data'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 33)
        nsgId: aiSubnetNsg.outputs.id
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: 'management'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 34)
        nsgId: aiSubnetNsg.outputs.id
      }
    ]
    tags: tags
  }
}

// --- Azure Firewall ---

module firewall '../../modules/security/firewall.bicep' = {
  params: {
    location: location
    firewallName: '${resourcePrefix}-fw'
    firewallSubnetId: vnet.outputs.subnets[0].id // AzureFirewallSubnet
    skuTier: firewallSkuTier
    tags: tags
  }
}

// Route table to force all traffic through firewall
resource routeTable 'Microsoft.Network/routeTables@2024-01-01' = {
  name: '${resourcePrefix}-rt'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewall.outputs.privateIp
        }
      }
    ]
  }
}

// --- Private DNS Zones ---

var dnsZoneNames = [
  'privatelink.openai.azure.com'
  'privatelink.search.windows.net'
  'privatelink.blob.core.windows.net'
  'privatelink.dfs.core.windows.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.api.azureml.ms'
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
    publicNetworkAccess: 'Disabled'
    enablePurgeProtection: true
    tags: tags
  }
}

// --- Storage (Private) ---

module storage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: '${cleanPrefix}adls'
    isHnsEnabled: true
    publicNetworkAccess: 'Disabled'
    containerNames: ['data', 'embeddings', 'models', 'audit-logs']
    tags: tags
  }
}

// --- AI Services (All Private) ---

module openAi '../../modules/ai/openai.bicep' = {
  params: {
    location: location
    openAiName: '${resourcePrefix}-openai'
    publicNetworkAccess: 'Disabled'
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
    publicNetworkAccess: 'disabled'
    tags: tags
  }
}

module machineLearning '../../modules/ai/machineLearning.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-aml'
    keyVaultId: keyVault.outputs.id
    storageAccountId: storage.outputs.id
    applicationInsightsId: appInsights.outputs.id
    publicNetworkAccess: 'Disabled'
    tags: tags
  }
}

// --- Compute (Private AKS) ---

module aks '../../modules/compute/aks.bicep' = {
  params: {
    location: location
    clusterName: '${resourcePrefix}-aks'
    subnetId: vnet.outputs.subnets[1].id
    systemNodeCount: aksSystemNodeCount
    enablePrivateCluster: true
    enableAzureRbac: true
    tags: tags
  }
}

// --- Private Endpoints (All Services) ---

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

module storageBlobPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-blob-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: storage.outputs.id
    groupIds: ['blob']
    privateDnsZoneId: dnsZones[2].outputs.id
    tags: tags
  }
}

module storageDfsPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-dfs-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: storage.outputs.id
    groupIds: ['dfs']
    privateDnsZoneId: dnsZones[3].outputs.id
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

module amlPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-aml-pe'
    subnetId: vnet.outputs.subnets[2].id
    privateLinkServiceId: machineLearning.outputs.id
    groupIds: ['amlworkspace']
    privateDnsZoneId: dnsZones[5].outputs.id
    tags: tags
  }
}

// --- Diagnostic Settings (Centralized Logging) ---

resource openAiDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourcePrefix}-openai-diag'
  scope: openAi
  properties: {
    workspaceId: logAnalytics.outputs.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// --- Outputs ---

@description('VNet ID')
output vnetId string = vnet.outputs.id

@description('Firewall private IP')
output firewallPrivateIp string = firewall.outputs.privateIp

@description('AKS cluster name (private)')
output aksClusterName string = aks.outputs.name

@description('OpenAI resource name')
output openAiName string = openAi.outputs.name

@description('AI Search name')
output aiSearchName string = aiSearch.outputs.name

@description('Key Vault name')
output keyVaultName string = keyVault.outputs.name

@description('Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.id
