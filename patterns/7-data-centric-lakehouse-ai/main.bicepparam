using './main.bicep'

param location = 'canadacentral'
param environmentName = 'dev'
param baseName = 'datalake'
param vnetAddressPrefix = '10.40.0.0/16'
param databricksTier = 'premium'
param deployAppService = true
param openAiDeployments = [
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
