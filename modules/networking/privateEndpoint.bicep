// Private Endpoint Module
// Creates a private endpoint with DNS zone integration

@description('Azure region')
param location string

@description('Name of the private endpoint')
param privateEndpointName string

@description('Subnet ID for the private endpoint')
param subnetId string

@description('Resource ID of the target service')
param privateLinkServiceId string

@description('Group IDs for the private link (e.g., account, vault, searchService)')
param groupIds string[]

@description('Private DNS Zone ID for auto-registration')
param privateDnsZoneId string

@description('Tags')
param tags object = {}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-01-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

@description('Private endpoint resource ID')
output id string = privateEndpoint.id

@description('Private IP addresses assigned')
output customDnsConfigs array = privateEndpoint.properties.customDnsConfigs
