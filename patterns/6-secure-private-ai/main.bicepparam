using './main.bicep'

param location = 'canadacentral'
param environmentName = 'prod'
param baseName = 'secureai'
param vnetAddressPrefix = '10.30.0.0/16'
param aksSystemNodeCount = 3
param firewallSkuTier = 'Premium'
param openAiDeployments = [
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
