using './main.bicep'

param location = 'canadacentral'
param environmentName = 'dev'
param baseName = 'aifactory'
param vnetAddressPrefix = '10.20.0.0/16'
param databricksTier = 'premium'
param containerRegistrySku = 'Premium'
param openAiDeployments = [
  {
    name: 'gpt-4o'
    modelName: 'gpt-4o'
    modelVersion: '2024-08-06'
    capacity: 30
    skuName: 'GlobalStandard'
  }
]
