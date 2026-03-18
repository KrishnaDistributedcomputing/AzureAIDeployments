using './main.bicep'

param location = 'canadacentral'
param environmentName = 'dev'
param baseName = 'hybrid'
param spokeWorkloadName = 'claims'
param hubVnetAddressPrefix = '10.0.0.0/16'
param spokeVnetAddressPrefix = '10.1.0.0/16'
param useAppService = true
param hubOpenAiDeployments = [
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
