// Azure Virtual Desktop - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-04-03'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'end-user-compute'
}

@description('Host pool type: Pooled or Personal')
param hostPoolType ('Pooled' | 'Personal') = 'Pooled'

@description('Desktop assignment type: Automatic for pooled, Direct for personal')
param personalDesktopAssignmentType ('Automatic' | 'Direct') = 'Automatic'

@description('Preferred app group type')
param preferredAppGroupType ('Desktop' | 'RailApplications') = 'Desktop'

@description('Validation environment for pre-production testing')
param validationEnvironment bool = false

var hostPoolName = 'avd-hp-${environment}-${uniqueString(resourceGroup().id)}'
var workspaceName = 'avd-ws-${environment}-${uniqueString(resourceGroup().id)}'
var appGroupName = 'avd-dag-${environment}-${uniqueString(resourceGroup().id)}'

// AVD Host Pool
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@${apiVersion}' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: hostPoolType == 'Pooled' ? 'DepthFirst' : 'Persistent'
    preferredAppGroupType: preferredAppGroupType
    validationEnvironment: validationEnvironment
    maxSessionLimit: hostPoolType == 'Pooled' ? 16 : 1
    personalDesktopAssignmentType: hostPoolType == 'Personal' ? personalDesktopAssignmentType : null
    startVMOnConnect: true
    publicNetworkAccess: 'Disabled'
    managementType: 'Automated'
  }
}

// AVD Workspace
resource workspace 'Microsoft.DesktopVirtualization/workspaces@${apiVersion}' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    description: 'AVD workspace for ${environment} environment'
    friendlyName: 'AVD Workspace ${toUpper(environment)}'
    publicNetworkAccess: 'Disabled'
  }
}

// Desktop Application Group
resource desktopAppGroup 'Microsoft.DesktopVirtualization/applicationGroups@${apiVersion}' = {
  name: appGroupName
  location: location
  tags: tags
  properties: {
    applicationGroupType: 'Desktop'
    hostPoolArmPath: hostPool.id
    friendlyName: 'Desktop App Group ${toUpper(environment)}'
    description: 'Desktop delivery for ${environment} users'
  }
}

// Workspace association with app group
resource appGroupAssociation 'Microsoft.DesktopVirtualization/workspaces/applicationGroups@${apiVersion}' = {
  parent: workspace
  name: last(split(desktopAppGroup.id, '/'))
  properties: {}
}

output hostPoolId string = hostPool.id
output hostPoolName string = hostPool.name
output workspaceId string = workspace.id
output workspaceName string = workspace.name
output applicationGroupId string = desktopAppGroup.id
output applicationGroupName string = desktopAppGroup.name
