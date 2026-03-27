// Azure Event Hubs - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-01-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'streaming'
}

@description('Event Hubs tier')
param skuName ('Basic' | 'Standard' | 'Premium') = 'Standard'

var namespaceName = 'eh-${environment}-${uniqueString(resourceGroup().id)}'
var hubName = 'telemetry'

resource eventHubsNamespace 'Microsoft.EventHub/namespaces@${apiVersion}' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
    capacity: skuName == 'Premium' ? 1 : 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    isAutoInflateEnabled: true
    maximumThroughputUnits: 20
    zoneRedundant: skuName == 'Premium'
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@${apiVersion}' = {
  parent: eventHubsNamespace
  name: hubName
  properties: {
    partitionCount: 4
    messageRetentionInDays: 7
    status: 'Active'
    captureDescription: {
      enabled: false
    }
  }
}

output namespaceId string = eventHubsNamespace.id
output namespaceName string = eventHubsNamespace.name
output eventHubId string = eventHub.id
