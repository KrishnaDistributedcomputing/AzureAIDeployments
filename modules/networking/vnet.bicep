// Virtual Network Module
// Deploys a VNet with configurable subnets for AI workloads

@description('Azure region for the VNet')
param location string

@description('Name of the virtual network')
param vnetName string

@description('Address prefix for the VNet')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet configurations')
param subnets subnetConfig[]

@description('Tags to apply to the VNet')
param tags object = {}

type subnetConfig = {
  @description('Name of the subnet')
  name: string
  @description('Address prefix for the subnet')
  addressPrefix: string
  @description('Optional NSG resource ID to associate')
  nsgId: string?
  @description('Optional route table resource ID')
  routeTableId: string?
  @description('Service endpoints to enable')
  serviceEndpoints: string[]?
  @description('Delegations for the subnet')
  delegations: string[]?
  @description('Whether to disable private endpoint network policies')
  privateEndpointNetworkPolicies: ('Disabled' | 'Enabled')?
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          networkSecurityGroup: subnet.nsgId != null
            ? { id: subnet.nsgId! }
            : null
          routeTable: subnet.routeTableId != null
            ? { id: subnet.routeTableId! }
            : null
          serviceEndpoints: [
            for ep in (subnet.serviceEndpoints ?? []): {
              service: ep
            }
          ]
          delegations: [
            for del in (subnet.delegations ?? []): {
              name: '${subnet.name}-delegation'
              properties: {
                serviceName: del
              }
            }
          ]
          privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies ?? 'Disabled'
        }
      }
    ]
  }
}

@description('Resource ID of the VNet')
output id string = vnet.id

@description('Name of the VNet')
output name string = vnet.name

@description('Subnet IDs keyed by name')
output subnets array = vnet.properties.subnets
