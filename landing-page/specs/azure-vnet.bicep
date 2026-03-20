// Virtual Network with Hub-Spoke - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-11-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'networking'
}

var hubVnetName = 'vnet-hub-${environment}'
var spokeVnetName = 'vnet-spoke-${environment}'

// Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@${apiVersion}' = {
  name: hubVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          serviceEndpoints: []
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.3.0/24'
          serviceEndpoints: [
            'Microsoft.KeyVault'
            'Microsoft.CognitiveServices'
            'Microsoft.Storage'
          ]
        }
      }
    ]
  }
}

// Spoke Virtual Network
resource spokeVnet 'Microsoft.Network/virtualNetworks@${apiVersion}' = {
  name: spokeVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
          serviceEndpoints: [
            'Microsoft.CognitiveServices'
            'Microsoft.Storage'
          ]
        }
      }
      {
        name: 'container-subnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
        }
      }
    ]
  }
}

// VNet Peering (Hub to Spoke)
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@${apiVersion}' = {
  parent: hubVnet
  name: 'hub-to-spoke'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}

// VNet Peering (Spoke to Hub)
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@${apiVersion}' = {
  parent: spokeVnet
  name: 'spoke-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: true
  }
}

output hubVnetId string = hubVnet.id
output spokeVnetId string = spokeVnet.id
output hubVnetName string = hubVnet.name
