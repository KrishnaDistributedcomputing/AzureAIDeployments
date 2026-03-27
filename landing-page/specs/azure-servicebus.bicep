// Azure Service Bus - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-01-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'messaging'
}

@description('Service Bus SKU tier')
param skuName ('Basic' | 'Standard' | 'Premium') = 'Standard'

var namespaceName = 'sb-${environment}-${uniqueString(resourceGroup().id)}'
var queueName = 'work-items'
var topicName = 'events'
var subscriptionName = 'processor-a'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@${apiVersion}' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
    capacity: skuName == 'Premium' ? 1 : null
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    minimumTlsVersion: '1.2'
    disableLocalAuth: true
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@${apiVersion}' = {
  parent: serviceBusNamespace
  name: queueName
  properties: {
    requiresDuplicateDetection: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
  }
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@${apiVersion}' = {
  parent: serviceBusNamespace
  name: topicName
  properties: {
    requiresDuplicateDetection: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enablePartitioning: true
  }
}

resource subscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@${apiVersion}' = {
  parent: topic
  name: subscriptionName
  properties: {
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
    requiresSession: false
  }
}

output namespaceId string = serviceBusNamespace.id
output namespaceName string = serviceBusNamespace.name
output queueResourceId string = queue.id
output topicResourceId string = topic.id
