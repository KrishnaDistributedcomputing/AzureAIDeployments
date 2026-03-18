// Azure Firewall Module
// Deploys Azure Firewall for network traffic control

@description('Azure region')
param location string

@description('Firewall name')
param firewallName string

@description('Firewall subnet ID (must be named AzureFirewallSubnet)')
param firewallSubnetId string

@description('Firewall SKU tier')
param skuTier ('Standard' | 'Premium') = 'Standard'

@description('Tags')
param tags object = {}

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: '${firewallName}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: '${firewallName}-policy'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: skuTier
    }
    threatIntelMode: 'Deny'
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: firewallName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: skuTier
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          publicIPAddress: {
            id: firewallPublicIp.id
          }
          subnet: {
            id: firewallSubnetId
          }
        }
      }
    ]
  }
}

@description('Firewall resource ID')
output id string = firewall.id

@description('Firewall private IP')
output privateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress

@description('Firewall policy ID')
output policyId string = firewallPolicy.id
