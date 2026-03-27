// Azure Front Door - Deployment Spec
param location string = 'global'
param environment string = 'prod'
param apiVersion string = '2024-05-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'edge-networking'
}

var profileName = 'afd-${environment}-${uniqueString(resourceGroup().id)}'
var endpointName = 'ep-${environment}-${uniqueString(resourceGroup().id)}'

resource profile 'Microsoft.Cdn/profiles@${apiVersion}' = {
  name: profileName
  location: location
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@${apiVersion}' = {
  parent: profile
  name: endpointName
  location: location
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@${apiVersion}' = {
  parent: profile
  name: 'default-origin-group'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
    healthProbeSettings: {
      probePath: '/health'
      probeRequestType: 'GET'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 120
    }
  }
}

output profileId string = profile.id
output endpointId string = endpoint.id
output endpointHostName string = endpoint.properties.hostName
