// Network Security Group Module
// Creates an NSG with configurable security rules

@description('Azure region')
param location string

@description('NSG name')
param nsgName string

@description('Security rules')
param securityRules nsgRule[] = []

@description('Tags')
param tags object = {}

type nsgRule = {
  @description('Rule name')
  name: string
  @description('Priority (100-4096)')
  priority: int
  @description('Direction')
  direction: ('Inbound' | 'Outbound')
  @description('Access')
  access: ('Allow' | 'Deny')
  @description('Protocol')
  protocol: ('Tcp' | 'Udp' | '*')
  @description('Source address prefix')
  sourceAddressPrefix: string
  @description('Source port range')
  sourcePortRange: string
  @description('Destination address prefix')
  destinationAddressPrefix: string
  @description('Destination port range')
  destinationPortRange: string
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      for rule in securityRules: {
        name: rule.name
        properties: {
          priority: rule.priority
          direction: rule.direction
          access: rule.access
          protocol: rule.protocol
          sourceAddressPrefix: rule.sourceAddressPrefix
          sourcePortRange: rule.sourcePortRange
          destinationAddressPrefix: rule.destinationAddressPrefix
          destinationPortRange: rule.destinationPortRange
        }
      }
    ]
  }
}

@description('NSG resource ID')
output id string = nsg.id

@description('NSG name')
output name string = nsg.name
