// Microsoft Fabric - Capacity Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-11-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'analytics-services'
}

var capacityName = 'fabric-${environment}-${uniqueString(resourceGroup().id)}'

resource fabricCapacity 'Microsoft.Fabric/capacities@${apiVersion}' = {
  name: capacityName
  location: location
  tags: tags
  sku: {
    name: 'F64'  // F64 = 64 CU (approximately 5000/mo cost)
    tier: 'Fabric'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administration: {
      members: [
        'user@organization.com'
      ]
    }
  }
}

output fabricCapacityId string = fabricCapacity.id
output fabricCapacityName string = fabricCapacity.name
