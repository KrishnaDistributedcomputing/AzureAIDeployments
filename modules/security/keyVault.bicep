// Azure Key Vault Module

@description('Azure region')
param location string

@description('Key Vault name')
param keyVaultName string

@description('SKU')
param skuName ('standard' | 'premium') = 'standard'

@description('Whether to enable soft delete')
param enableSoftDelete bool = true

@description('Soft delete retention in days')
param softDeleteRetentionInDays int = 90

@description('Whether to enable purge protection')
param enablePurgeProtection bool = true

@description('Whether to disable public network access')
param publicNetworkAccess ('Enabled' | 'Disabled') = 'Disabled'

@description('Tenant ID')
param tenantId string = subscription().tenantId

@description('Tags')
param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
    enableRbacAuthorization: true
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
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

@description('Key Vault resource ID')
output id string = keyVault.id

@description('Key Vault name')
output name string = keyVault.name

@description('Key Vault URI')
output vaultUri string = keyVault.properties.vaultUri
