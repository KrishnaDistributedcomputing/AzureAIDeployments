// API Management Module
// Deploys APIM for AI API gateway scenarios

@description('Azure region')
param location string

@description('APIM service name')
param apimName string

@description('Publisher email')
param publisherEmail string

@description('Publisher name')
param publisherName string

@description('SKU name')
param skuName ('Consumption' | 'Developer' | 'Basic' | 'Standard' | 'Premium') = 'Consumption'

@description('SKU capacity (ignored for Consumption)')
param skuCapacity int = 0

@description('Tags')
param tags object = {}

resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuName == 'Consumption' ? 0 : skuCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

@description('APIM resource ID')
output id string = apim.id

@description('APIM gateway URL')
output gatewayUrl string = apim.properties.gatewayUrl

@description('APIM principal ID')
output principalId string = apim.identity.principalId
