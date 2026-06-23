targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Storage account name.')
param storageAccountName string

@description('Storage account SKU name.')
param storageSkuName string = 'Standard_LRS'

@description('Deploy Azure Files demo share.')
param deployAzureFiles bool = true

@description('Tags applied to resources.')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: storageSkuName
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    largeFileSharesState: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = if (deployAzureFiles) {
  parent: storageAccount
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource demoShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = if (deployAzureFiles) {
  parent: fileService
  name: 'demo-share'
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 100
    enabledProtocols: 'SMB'
  }
}

@description('Storage account resource ID.')
output storageAccountId string = storageAccount.id

@description('Storage account name.')
output storageAccountName string = storageAccount.name

@description('Azure file share name.')
output fileShareName string = deployAzureFiles ? demoShare.name : ''
