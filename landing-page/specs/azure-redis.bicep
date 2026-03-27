// Azure Cache for Redis - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-03-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'cache'
}

@description('Redis SKU family')
param skuFamily ('C' | 'P') = 'C'

@description('Redis SKU name')
param skuName ('Basic' | 'Standard' | 'Premium') = 'Standard'

@description('Redis capacity')
param skuCapacity int = 1

var redisName = 'redis-${environment}-${uniqueString(resourceGroup().id)}'

resource redis 'Microsoft.Cache/Redis@${apiVersion}' = {
  name: redisName
  location: location
  tags: tags
  properties: {
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
  sku: {
    name: skuName
    family: skuFamily
    capacity: skuCapacity
  }
}

output redisId string = redis.id
output redisName string = redis.name
output redisHostName string = redis.properties.hostName
