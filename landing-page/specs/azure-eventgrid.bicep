// Event Grid Topic - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-12-15-preview'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'event-services'
}

var topicName = 'eg-${environment}-${uniqueString(resourceGroup().id)}'

// Event Grid Topic
resource eventGridTopic 'Microsoft.EventGrid/topics@${apiVersion}' = {
  name: topicName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    inboundIpRules: []
    disableLocalAuth: false
    inputSchema: 'EventGridSchema'
    dataResidencyBoundary: 'WithinGeopair'
  }
}

// Event Subscription
resource eventSubscription 'Microsoft.EventGrid/topics/eventSubscriptions@${apiVersion}' = {
  parent: eventGridTopic
  name: 'webhook-subscription'
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: 'https://your-webhook.azurewebsites.net/api/events'
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
    }
    filter: {
      subjectBeginsWith: ''
      subjectEndsWith: ''
      includedEventTypes: [
        'All'
      ]
      isSubjectCaseSensitive: false
      enableAdvancedFilteringOnArrays: true
    }
    labels: []
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxNumberOfAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
    deadLetterDestination: {
      endpointType: 'StorageBlob'
      properties: {
        resourceId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Storage/storageAccounts/{storageAccount}/blobServices/default/containers/deadletter'
      }
    }
  }
}

output topicId string = eventGridTopic.id
output topicEndpoint string = eventGridTopic.properties.endpoint
output subscriptionId string = eventSubscription.id
