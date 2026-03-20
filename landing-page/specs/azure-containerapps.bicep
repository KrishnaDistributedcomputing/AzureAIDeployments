// Container Apps - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-03-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'compute-services'
}

var containerAppEnvName = 'cae-${environment}-${uniqueString(resourceGroup().id)}'
var logAnalyticsWorkspaceName = 'law-${environment}-${uniqueString(resourceGroup().id)}'

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Container App Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@${apiVersion}' = {
  name: containerAppEnvName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: true
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@${apiVersion}' = {
  name: 'app-${environment}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
      }
      registries: [
        {
          server: 'your-registry.azurecr.io'
          username: 'username'
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: 'your-registry.azurecr.io/app:latest'
          name: 'main-container'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

output containerAppEnvId string = containerAppEnv.id
output containerAppId string = containerApp.id
output containerAppUrl string = containerApp.properties.configuration.ingress.fqdn
