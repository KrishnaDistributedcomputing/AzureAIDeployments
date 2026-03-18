// Private DNS Zone Module
// Creates a private DNS zone with optional VNet link

@description('DNS zone name (e.g., privatelink.openai.azure.com)')
param zoneName string

@description('VNet ID to link the DNS zone to')
param vnetId string

@description('Tags')
param tags object = {}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: zoneName
  location: 'global'
  tags: tags
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: '${replace(zoneName, '.', '-')}-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

@description('DNS zone resource ID')
output id string = privateDnsZone.id

@description('DNS zone name')
output name string = privateDnsZone.name
