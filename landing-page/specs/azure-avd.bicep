// Azure Virtual Desktop - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2022-09-09'
param hostPoolType string = 'Pooled'
param maxSessionLimit int = 10
param loadBalancerType string = 'BreadthFirst'
param startVMOnConnect bool = true
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'virtual-desktop'
}

var hostPoolName = 'vdpool-${environment}-${uniqueString(resourceGroup().id)}'
var appGroupName = 'vdag-desktop-${environment}'
var workspaceName = 'vdws-${environment}-${uniqueString(resourceGroup().id)}'
var logAnalyticsWorkspaceName = 'law-avd-${environment}-${uniqueString(resourceGroup().id)}'

// Log Analytics Workspace for AVD diagnostics
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// AVD Host Pool
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@${apiVersion}' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: maxSessionLimit
    startVMOnConnect: startVMOnConnect
    validationEnvironment: false
    registrationInfo: {
      expirationTime: dateTimeAdd(utcNow(), 'P1D')
      registrationTokenOperation: 'Update'
    }
    agentUpdate: {
      type: 'Scheduled'
      maintenanceWindows: [
        {
          dayOfWeek: 'Sunday'
          hour: 2
        }
      ]
    }
  }
}

// AVD Application Group (Desktop)
resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@${apiVersion}' = {
  name: appGroupName
  location: location
  tags: tags
  properties: {
    hostPoolArmPath: hostPool.id
    applicationGroupType: 'Desktop'
    description: 'Desktop application group for ${environment} environment'
  }
}

// AVD Workspace
resource workspace 'Microsoft.DesktopVirtualization/workspaces@${apiVersion}' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    applicationGroupReferences: [
      applicationGroup.id
    ]
    description: 'AVD workspace for ${environment} environment'
  }
}

// Diagnostic Settings for Host Pool
resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${hostPoolName}'
  scope: hostPool
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output hostPoolId string = hostPool.id
output hostPoolName string = hostPool.name
output applicationGroupId string = applicationGroup.id
output workspaceId string = workspace.id
output registrationToken string = hostPool.properties.registrationInfo.token
