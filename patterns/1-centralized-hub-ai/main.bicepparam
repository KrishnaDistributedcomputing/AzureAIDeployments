using './main.bicep'

param location = 'canadacentral'
param environmentName = 'dev'
param baseName = 'hubai'
param spokeCount = 2
param spokeVnetAddressPrefixes = [
  '10.1.0.0/16'
  '10.2.0.0/16'
]
param openAiDeployments = [
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
