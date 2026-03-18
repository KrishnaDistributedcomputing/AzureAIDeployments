// Azure Machine Learning Workspace Module

@description('Azure region')
param location string

@description('Workspace name')
param workspaceName string

@description('Key Vault resource ID')
param keyVaultId string

@description('Storage account resource ID')
param storageAccountId string

@description('Application Insights resource ID')
param applicationInsightsId string

@description('Container Registry resource ID (optional)')
param containerRegistryId string = ''

@description('Whether to disable public network access')
param publicNetworkAccess ('Enabled' | 'Disabled') = 'Enabled'

@description('Managed identity type')
param identityType ('SystemAssigned' | 'UserAssigned') = 'SystemAssigned'

@description('Tags')
param tags object = {}

resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  identity: {
    type: identityType
  }
  properties: {
    friendlyName: workspaceName
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: applicationInsightsId
    containerRegistry: !empty(containerRegistryId) ? containerRegistryId : null
    publicNetworkAccess: publicNetworkAccess
  }
}

@description('Workspace resource ID')
output id string = workspace.id

@description('Workspace name')
output name string = workspace.name

@description('Workspace principal ID')
output principalId string = workspace.identity.principalId
