// Azure Databricks Workspace Module

@description('Azure region')
param location string

@description('Databricks workspace name')
param workspaceName string

@description('Pricing tier')
param pricingTier ('standard' | 'premium') = 'premium'

@description('Managed resource group name')
param managedResourceGroupName string = ''

@description('Custom VNet ID (for VNet injection)')
param customVirtualNetworkId string = ''

@description('Public subnet name (for VNet injection)')
param publicSubnetName string = ''

@description('Private subnet name (for VNet injection)')
param privateSubnetName string = ''

@description('Whether to disable public network access')
param publicNetworkAccess ('Enabled' | 'Disabled') = 'Enabled'

@description('Tags')
param tags object = {}

var vnetInjection = !empty(customVirtualNetworkId)

resource databricks 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: workspaceName
  location: location
  tags: tags
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: !empty(managedResourceGroupName)
      ? '${subscription().id}/resourceGroups/${managedResourceGroupName}'
      : '${subscription().id}/resourceGroups/databricks-rg-${workspaceName}'
    publicNetworkAccess: publicNetworkAccess
    parameters: vnetInjection
      ? {
          customVirtualNetworkId: { value: customVirtualNetworkId }
          customPublicSubnetName: { value: publicSubnetName }
          customPrivateSubnetName: { value: privateSubnetName }
        }
      : {}
  }
}

@description('Databricks workspace resource ID')
output id string = databricks.id

@description('Databricks workspace URL')
output workspaceUrl string = databricks.properties.workspaceUrl

@description('Databricks workspace name')
output name string = databricks.name
