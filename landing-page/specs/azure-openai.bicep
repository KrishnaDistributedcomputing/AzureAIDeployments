// Azure OpenAI Service - Complete Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-10-01-preview'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'ai-services'
}

var resourceName = 'openai-${environment}-${uniqueString(resourceGroup().id)}'

resource openaiAccount 'Microsoft.CognitiveServices/accounts@${apiVersion}' = {
  name: resourceName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  tags: tags
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    customSubdomainName: resourceName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
  }
}

// GPT-4 Deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@${apiVersion}' = {
  parent: openaiAccount
  name: 'gpt-4-deployment'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '1106'
    }
    scaleSettings: {
      scaleType: 'Standard'
      capacity: 20
    }
  }
}

// GPT-4 Turbo Deployment
resource gpt4TurboDeployment 'Microsoft.CognitiveServices/accounts/deployments@${apiVersion}' = {
  parent: openaiAccount
  name: 'gpt-4-turbo-deployment'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4-turbo'
      version: '2024-04-09'
    }
    scaleSettings: {
      scaleType: 'Standard'
      capacity: 30
    }
  }
}

// Text Embedding Deployment
resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@${apiVersion}' = {
  parent: openaiAccount
  name: 'text-embedding-3-large'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
      version: '1'
    }
    scaleSettings: {
      scaleType: 'Standard'
      capacity: 25
    }
  }
}

output openaiEndpoint string = openaiAccount.properties.endpoint
output openaiId string = openaiAccount.id
output gpt4DeploymentId string = gpt4Deployment.id
output embeddingDeploymentId string = embeddingDeployment.id
