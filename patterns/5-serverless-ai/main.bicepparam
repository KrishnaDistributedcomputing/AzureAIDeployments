using './main.bicep'

param location = 'canadacentral'
param environmentName = 'dev'
param baseName = 'serverlessai'
param deployApim = false
param functionRuntime = 'python'
param openAiDeployments = [
  {
    name: 'gpt-4o-mini'
    modelName: 'gpt-4o-mini'
    modelVersion: '2024-07-18'
    capacity: 20
    skuName: 'GlobalStandard'
  }
  {
    name: 'text-embedding-3-small'
    modelName: 'text-embedding-3-small'
    modelVersion: '1'
    capacity: 60
    skuName: 'Standard'
  }
]
