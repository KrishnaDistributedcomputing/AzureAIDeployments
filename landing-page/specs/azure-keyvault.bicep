// Key Vault - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-07-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'security-services'
}

var vaultName = 'kv-${environment}-${uniqueString(resourceGroup().id)}'

resource keyVault 'Microsoft.KeyVault/vaults@${apiVersion}' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Enable purge protection
resource keyVaultPurgePolicy 'Microsoft.KeyVault/vaults@${apiVersion}' = {
  name: keyVault.name
  location: location
  tags: tags
  properties: {
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
