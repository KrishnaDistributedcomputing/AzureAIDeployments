// Azure Virtual Network (DS-VNET-001) - Hub-Spoke Deployment Specification
// Provides foundational networking with multi-subnet segmentation, NSG readiness, and peering support
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-05-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'networking'
  spec: 'DS-VNET-001'
}

var hubVnetName = 'vnet-hub-${environment}'
var spokeVnetName = 'vnet-spoke-${environment}'

// Hub Virtual Network - Central inspection point
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
          serviceEndpoints: []
        }
      }
      {
        name: 'BastionSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
          serviceEndpoints: []
        }
      }
      {
        name: 'management'
        properties: {
          addressPrefix: '10.0.4.0/24'
          serviceEndpoints: [
            'Microsoft.KeyVault'
            'Microsoft.Storage'
          ]
        }
      }
    ]
  }
}

// Spoke Virtual Network - Application workload isolation
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
            'Microsoft.Storage'
            'Microsoft.KeyVault'
            'Microsoft.CognitiveServices'
          ]
        }
      }
      {
        name: 'container-subnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
          serviceEndpoints: [
            'Microsoft.Storage'
            'Microsoft.ContainerRegistry'
          ]
        }
      }
      {
        name: 'database-subnet'
        properties: {
          addressPrefix: '10.1.3.0/24'
          serviceEndpoints: [
            'Microsoft.Sql'
          ]
        }
      }
    ]
  }
}

// VNet Peering (Hub to Spoke) - Allows hub gateway transit and forwarded traffic
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

// VNet Peering (Spoke to Hub) - Enables spoke-to-spoke traffic via hub firewall
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

// Outputs for downstream resource references
output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output spokeVnetId string = spokeVnet.id
output spokeVnetName string = spokeVnet.name
output hubFirewallSubnetId string = '${hubVnet.id}/subnets/AzureFirewallSubnet'
output hubGatewaySubnetId string = '${hubVnet.id}/subnets/GatewaySubnet'
output hubBastionSubnetId string = '${hubVnet.id}/subnets/BastionSubnet'
output hubManagementSubnetId string = '${hubVnet.id}/subnets/management'
output spokeAppSubnetId string = '${spokeVnet.id}/subnets/app-subnet'
output spokeContainerSubnetId string = '${spokeVnet.id}/subnets/container-subnet'
output spokeDatabaseSubnetId string = '${spokeVnet.id}/subnets/database-subnet'
output tags object = tags
output deploymentLocation string = location
