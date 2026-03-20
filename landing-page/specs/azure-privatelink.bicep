// Private Link - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-11-01'
param vnetId string
param subnetId string
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'networking'
}

// Private Endpoint for Cognitive Services
resource privateEndpoint 'Microsoft.Network/privateEndpoints@${apiVersion}' = {
  name: 'pep-openai-${environment}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-connection'
        properties: {
          privateLinkServiceId: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.CognitiveServices/accounts/{accountName}'
          groupIds: [
            'account'
          ]
          requestMessage: ''
        }
      }
    ]
    customNetworkInterfaceName: 'nic-pep-openai'
  }
}

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@${apiVersion}' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  tags: tags
}

// Private DNS Zone Link
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@${apiVersion}' = {
  parent: privateDnsZone
  name: 'vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// DNS A Record
resource dnsARecord 'Microsoft.Network/privateDnsZones/A@${apiVersion}' = {
  parent: privateDnsZone
  name: 'your-resource'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpoint.properties.networkInterfaces[0].properties.ipConfigurations[0].properties.privateIPAddress
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
output privateDnsZoneId string = privateDnsZone.id
