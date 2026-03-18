// ============================================================================
// Pattern 4: AI Factory Pattern (MLOps Landing Zone)
// ============================================================================
// A dedicated AI Factory Landing Zone for the full ML lifecycle.
// Separate subscription under Platform for training, registry, CI/CD, and
// continuous retraining pipelines.
//
// Components: AML (pipelines, registry), Databricks (training), ADLS Gen2
//             (feature store), GitHub/DevOps (CI/CD), App Insights, Log Analytics
//
// Use Cases: Large-scale ML pipelines, continuous retraining, enterprise AI
// ============================================================================

targetScope = 'resourceGroup'

// --- Parameters ---

@description('Azure region')
param location string = 'canadacentral'

@description('Environment name')
param environmentName ('dev' | 'staging' | 'prod') = 'dev'

@description('Base name prefix')
param baseName string = 'aifactory'

@description('Tags')
param tags object = {
  pattern: 'ai-factory-mlops'
  environment: environmentName
}

@description('VNet address prefix')
param vnetAddressPrefix string = '10.20.0.0/16'

@description('Databricks pricing tier')
param databricksTier ('standard' | 'premium') = 'premium'

@description('OpenAI deployments for inference endpoints')
param openAiDeployments array = [
  {
    name: 'gpt-4o'
    modelName: 'gpt-4o'
    modelVersion: '2024-08-06'
    capacity: 30
    skuName: 'GlobalStandard'
  }
]

@description('Container Registry SKU')
param containerRegistrySku ('Basic' | 'Standard' | 'Premium') = 'Premium'

// --- Variables ---

var resourcePrefix = '${baseName}-${environmentName}'
var cleanPrefix = replace('${baseName}${environmentName}', '-', '')

// --- Monitoring ---

module logAnalytics '../../modules/monitoring/logAnalytics.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-law'
    retentionInDays: 120
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

module vnet '../../modules/networking/vnet.bicep' = {
  params: {
    location: location
    vnetName: '${resourcePrefix}-vnet'
    addressPrefix: vnetAddressPrefix
    subnets: [
      { name: 'ml-compute', addressPrefix: cidrSubnet(vnetAddressPrefix, 22, 0) }
      {
        name: 'databricks-public'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 22, 1)
        delegations: ['Microsoft.Databricks/workspaces']
      }
      {
        name: 'databricks-private'
        addressPrefix: cidrSubnet(vnetAddressPrefix, 22, 2)
        delegations: ['Microsoft.Databricks/workspaces']
      }
      { name: 'private-endpoints', addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 12), privateEndpointNetworkPolicies: 'Disabled' }
      { name: 'data', addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 13), privateEndpointNetworkPolicies: 'Disabled' }
    ]
    tags: tags
  }
}

// Private DNS Zones
var dnsZoneNames = [
  'privatelink.openai.azure.com'
  'privatelink.blob.core.windows.net'
  'privatelink.dfs.core.windows.net'
  'privatelink.vaultcore.azure.net'
  'privatelink.api.azureml.ms'
  'privatelink.azurecr.io'
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

// --- Container Registry (for ML model images) ---

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${cleanPrefix}acr'
  location: location
  tags: tags
  sku: {
    name: containerRegistrySku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    policies: {
      retentionPolicy: {
        status: 'enabled'
        days: 30
      }
    }
  }
}

// --- Storage (Feature Store + Training Data) ---

module featureStore '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: '${cleanPrefix}features'
    isHnsEnabled: true
    containerNames: ['feature-store', 'training-data', 'model-artifacts', 'experiment-outputs']
    tags: tags
  }
}

module modelStorage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: '${cleanPrefix}models'
    isHnsEnabled: true
    containerNames: ['registered-models', 'model-packages', 'serving-artifacts']
    tags: tags
  }
}

// --- AI / ML Services ---

module openAi '../../modules/ai/openai.bicep' = {
  params: {
    location: location
    openAiName: '${resourcePrefix}-openai'
    deployments: openAiDeployments
    tags: tags
  }
}

module machineLearning '../../modules/ai/machineLearning.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-aml'
    keyVaultId: keyVault.outputs.id
    storageAccountId: featureStore.outputs.id
    applicationInsightsId: appInsights.outputs.id
    containerRegistryId: containerRegistry.id
    tags: tags
  }
}

// --- Databricks (Training + Feature Engineering) ---

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

// --- Private Endpoints ---

module openAiPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-openai-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: openAi.outputs.id
    groupIds: ['account']
    privateDnsZoneId: dnsZones[0].outputs.id
    tags: tags
  }
}

module featureStorePe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-features-blob-pe'
    subnetId: vnet.outputs.subnets[4].id
    privateLinkServiceId: featureStore.outputs.id
    groupIds: ['blob']
    privateDnsZoneId: dnsZones[1].outputs.id
    tags: tags
  }
}

module keyVaultPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-kv-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: keyVault.outputs.id
    groupIds: ['vault']
    privateDnsZoneId: dnsZones[3].outputs.id
    tags: tags
  }
}

module acrPe '../../modules/networking/privateEndpoint.bicep' = {
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-acr-pe'
    subnetId: vnet.outputs.subnets[3].id
    privateLinkServiceId: containerRegistry.id
    groupIds: ['registry']
    privateDnsZoneId: dnsZones[5].outputs.id
    tags: tags
  }
}

// --- Outputs ---

@description('AML workspace name')
output amlWorkspaceName string = machineLearning.outputs.name

@description('Databricks workspace URL')
output databricksWorkspaceUrl string = databricks.outputs.workspaceUrl

@description('Feature store account name')
output featureStoreName string = featureStore.outputs.name

@description('Container registry login server')
output acrLoginServer string = containerRegistry.properties.loginServer

@description('OpenAI endpoint')
output openAiEndpoint string = openAi.outputs.endpoint

@description('VNet ID')
output vnetId string = vnet.outputs.id
