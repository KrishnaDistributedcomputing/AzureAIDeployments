using './main.bicep'

param location = 'canadacentral'
param environmentName = 'dev'
param workloadName = 'claims-ai'
param vnetAddressPrefix = '10.10.0.0/16'
param aksSystemNodeCount = 3
param aksAiNodeCount = 0
param openAiDeployments = [
  {
    name: 'gpt-4o'
    modelName: 'gpt-4o'
    modelVersion: '2024-08-06'
    capacity: 20
    skuName: 'GlobalStandard'
  }
  {
    name: 'text-embedding-3-large'
    modelName: 'text-embedding-3-large'
    modelVersion: '1'
    capacity: 80
    skuName: 'Standard'
  }
]
