// Azure SQL Managed Instance - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-08-01-preview'
@secure()
@description('SQL MI Administrator password (must meet complexity requirements)')
param sqlAdminPassword string
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'data-services'
}

var instanceName = 'sqlmi-${environment}-${uniqueString(resourceGroup().id)}'

resource sqlManagedInstance 'Microsoft.Sql/managedInstances@${apiVersion}' = {
  name: instanceName
  location: location
  tags: tags
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    capacity: 4
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: 'azureAdmin'
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    storageAccount: {
      storageAccountId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Storage/storageAccounts/{storageAccount}'
    }
    subnetId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}'
    proxyOverride: 'Redirect'
    timezoneId: 'UTC'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    minimalTlsVersion: '1.2'
    keyId: null
    publicDataEndpointEnabled: false
  }
}

output sqlMiId string = sqlManagedInstance.id
output sqlMiFqdn string = sqlManagedInstance.properties.fullyQualifiedDomainName
