// ADLS Gen2 Storage Account Module
// Deploys Azure Data Lake Storage Gen2

@description('Azure region')
param location string

@description('Storage account name (3-24 lowercase alphanumeric)')
param storageAccountName string

@description('SKU')
param skuName ('Standard_LRS' | 'Standard_GRS' | 'Standard_ZRS' | 'Standard_RAGRS') = 'Standard_LRS'

@description('Whether to enable hierarchical namespace (Data Lake)')
param isHnsEnabled bool = true

@description('Whether to disable public network access')
param publicNetworkAccess ('Enabled' | 'Disabled') = 'Enabled'

@description('Container names to create')
param containerNames string[] = []

@description('Tags')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    accessTier: 'Hot'
    isHnsEnabled: isHnsEnabled
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: publicNetworkAccess
    networkAcls: publicNetworkAccess == 'Disabled'
      ? {
          defaultAction: 'Deny'
          bypass: 'AzureServices'
        }
      : {
          defaultAction: 'Allow'
        }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [
  for name in containerNames: {
    parent: blobService
    name: name
    properties: {
      publicAccess: 'None'
    }
  }
]

@description('Storage account resource ID')
output id string = storageAccount.id

@description('Storage account name')
output name string = storageAccount.name

@description('Primary blob endpoint')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Primary DFS endpoint (Data Lake)')
output primaryDfsEndpoint string = storageAccount.properties.primaryEndpoints.dfs
