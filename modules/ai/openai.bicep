// Azure OpenAI Module
// Deploys Azure OpenAI (Cognitive Services) with model deployments

@description('Azure region')
param location string

@description('Name of the Azure OpenAI resource')
param openAiName string

@description('SKU name')
param skuName string = 'S0'

@description('Whether to disable public network access')
param publicNetworkAccess ('Enabled' | 'Disabled') = 'Enabled'

@description('Model deployments to create')
param deployments modelDeployment[] = []

@description('Custom subdomain name')
param customSubDomainName string = openAiName

@description('Tags')
param tags object = {}

type modelDeployment = {
  @description('Deployment name')
  name: string
  @description('Model name (e.g., gpt-4o, gpt-4, text-embedding-ada-002)')
  modelName: string
  @description('Model version')
  modelVersion: string
  @description('Model format (OpenAI)')
  modelFormat: string?
  @description('Capacity in TPM units (thousands of tokens per minute)')
  capacity: int?
  @description('SKU name for the deployment')
  skuName: ('Standard' | 'GlobalStandard' | 'ProvisionedManaged')?
}

resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  kind: 'OpenAI'
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: publicNetworkAccess == 'Disabled'
      ? {
          defaultAction: 'Deny'
        }
      : null
  }
}

resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [
  for deployment in deployments: {
    parent: openAi
    name: deployment.name
    sku: {
      name: deployment.skuName ?? 'Standard'
      capacity: deployment.capacity ?? 10
    }
    properties: {
      model: {
        format: deployment.modelFormat ?? 'OpenAI'
        name: deployment.modelName
        version: deployment.modelVersion
      }
    }
  }
]

@description('Azure OpenAI resource ID')
output id string = openAi.id

@description('Azure OpenAI endpoint')
output endpoint string = openAi.properties.endpoint

@description('Azure OpenAI resource name')
output name string = openAi.name
