// Azure Firewall - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-11-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'networking'
}

var publicIpName = 'pip-firewall-${environment}'
var firewallName = 'afw-${environment}-${uniqueString(resourceGroup().id)}'

// Public IP
resource publicIp 'Microsoft.Network/publicIPAddresses@${apiVersion}' = {
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
    idleTimeoutInMinutes: 4
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@${apiVersion}' = {
  name: firewallName
  location: location
  tags: tags
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'config1'
        properties: {
          subnet: {
            id: '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'allow-outbound'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-https'
            protocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '443'
            ]
          }
        ]
      }
    ]
    applicationRuleCollections: [
      {
        name: 'allow-azure-services'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-openai'
            sourceAddresses: [
              '*'
            ]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              '*.openai.azure.com'
            ]
          }
        ]
      }
    ]
  }
}

output firewallId string = firewall.id
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
