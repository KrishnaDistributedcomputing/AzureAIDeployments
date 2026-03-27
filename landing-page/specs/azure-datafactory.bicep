// Azure Data Factory - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2018-06-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'data-integration'
}

@description('Enable managed virtual network')
param managedVirtualNetworkEnabled bool = true

var dataFactoryName = 'adf-${environment}-${uniqueString(resourceGroup().id)}'

resource dataFactory 'Microsoft.DataFactory/factories@${apiVersion}' = {
  name: dataFactoryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource integrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@${apiVersion}' = {
  parent: dataFactory
  name: 'AutoResolveIntegrationRuntime'
  properties: {
    type: 'Managed'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
        dataFlowProperties: {
          computeType: 'General'
          coreCount: 8
          timeToLive: 10
        }
      }
      managedVirtualNetwork: managedVirtualNetworkEnabled ? {
        referenceName: 'default'
        type: 'ManagedVirtualNetworkReference'
      } : null
    }
  }
}

output dataFactoryId string = dataFactory.id
output dataFactoryName string = dataFactory.name
output principalId string = dataFactory.identity.principalId
