// ============================================================================
// Pattern 5: Serverless AI Pattern (Lightweight / PoC)
// ============================================================================
// Minimal infrastructure using fully managed services within a single region.
// Ideal for internal copilots, MVPs, rapid prototyping, and low-ops apps.
//
// Components: Azure OpenAI, Azure Functions / Logic Apps, AI Search,
//             Storage Account, Optional API Management
//
// Landing Zone: App Landing Zone or Sandbox Subscription
// ============================================================================

targetScope = 'resourceGroup'

// --- Parameters ---

@description('Azure region')
param location string = 'canadacentral'

@description('Environment name')
param environmentName ('dev' | 'staging' | 'prod') = 'dev'

@description('Base name prefix')
param baseName string = 'serverlessai'

@description('Tags')
param tags object = {
  pattern: 'serverless-ai'
  environment: environmentName
}

@description('OpenAI model deployments')
param openAiDeployments array = [
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

@description('Whether to deploy API Management')
param deployApim bool = false

@description('APIM publisher email (required if deployApim is true)')
param apimPublisherEmail string = 'admin@contoso.com'

@description('APIM publisher name')
param apimPublisherName string = 'AI Platform Team'

@description('Function App runtime')
param functionRuntime ('python' | 'node' | 'dotnet-isolated') = 'python'

// --- Variables ---

var resourcePrefix = '${baseName}-${environmentName}'
var cleanPrefix = replace('${baseName}${environmentName}', '-', '')

// --- Monitoring ---

module logAnalytics '../../modules/monitoring/logAnalytics.bicep' = {
  params: {
    location: location
    workspaceName: '${resourcePrefix}-law'
    retentionInDays: 30
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

// --- Storage ---

module storage '../../modules/storage/adlsGen2.bicep' = {
  params: {
    location: location
    storageAccountName: '${cleanPrefix}sa'
    isHnsEnabled: false // Standard blob for serverless simplicity
    containerNames: ['documents', 'embeddings']
    tags: tags
  }
}

// --- AI Services ---

module openAi '../../modules/ai/openai.bicep' = {
  params: {
    location: location
    openAiName: '${resourcePrefix}-openai'
    deployments: openAiDeployments
    tags: tags
  }
}

module aiSearch '../../modules/ai/aiSearch.bicep' = {
  params: {
    location: location
    searchName: '${resourcePrefix}-search'
    sku: 'basic'
    semanticSearch: 'free'
    replicaCount: 1
    partitionCount: 1
    tags: tags
  }
}

// --- Compute (Serverless Functions) ---

module functionApp '../../modules/compute/functionApp.bicep' = {
  params: {
    location: location
    functionAppName: '${resourcePrefix}-func'
    appServicePlanName: '${resourcePrefix}-func-asp'
    storageAccountName: '${cleanPrefix}funcsa'
    appInsightsConnectionString: appInsights.outputs.connectionString
    runtime: functionRuntime
    appSettings: [
      { name: 'AZURE_OPENAI_ENDPOINT', value: openAi.outputs.endpoint }
      { name: 'AZURE_SEARCH_SERVICE', value: aiSearch.outputs.name }
      { name: 'AZURE_STORAGE_ACCOUNT', value: storage.outputs.name }
    ]
    tags: tags
  }
}

// --- Optional: API Management (Consumption tier) ---

module apim '../../modules/gateway/apim.bicep' = if (deployApim) {
  params: {
    location: location
    apimName: '${resourcePrefix}-apim'
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    skuName: 'Consumption'
    tags: tags
  }
}

// --- Outputs ---

@description('Azure OpenAI endpoint')
output openAiEndpoint string = openAi.outputs.endpoint

@description('AI Search service name')
output aiSearchName string = aiSearch.outputs.name

@description('Function App hostname')
output functionAppHostName string = functionApp.outputs.defaultHostName

@description('Storage account name')
output storageAccountName string = storage.outputs.name

@description('APIM gateway URL (if deployed)')
output apimGatewayUrl string = deployApim ? apim.outputs.gatewayUrl : 'Not deployed'
