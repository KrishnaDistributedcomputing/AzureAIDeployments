// Azure Bastion - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-11-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'networking'
}

var bastionName = 'bastion-${environment}'
var publicIpName = 'pip-bastion-${environment}'

// Public IP for Bastion
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@${apiVersion}' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@${apiVersion}' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableTunneling: true
  }
}

output bastionId string = bastion.id
output bastionName string = bastion.name
