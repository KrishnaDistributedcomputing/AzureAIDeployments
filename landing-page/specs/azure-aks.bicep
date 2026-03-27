// AKS - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-05-01'
param kubernetesVersion string = '1.30'
param dnsPrefix string = 'aks-${environment}'
param nodeVmSize string = 'Standard_D4s_v5'
param minNodeCount int = 2
param maxNodeCount int = 6
param enablePrivateCluster bool = true
param networkPlugin string = 'azure'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'compute-services'
}

var aksName = 'aks-${environment}-${uniqueString(resourceGroup().id)}'
var logAnalyticsWorkspaceName = 'law-aks-${environment}-${uniqueString(resourceGroup().id)}'

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

resource aksCluster 'Microsoft.ContainerService/managedClusters@${apiVersion}' = {
  name: aksName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: dnsPrefix
    enableRBAC: true
    supportPlan: 'KubernetesOfficial'
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
      enablePrivateClusterPublicFQDN: false
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: minNodeCount
        vmSize: nodeVmSize
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        orchestratorVersion: kubernetesVersion
        enableAutoScaling: true
        minCount: minNodeCount
        maxCount: maxNodeCount
      }
    ]
    networkProfile: {
      networkPlugin: networkPlugin
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
      azurepolicy: {
        enabled: true
      }
    }
  }
}

output aksId string = aksCluster.id
output aksName string = aksCluster.name
output aksFqdn string = aksCluster.properties.fqdn
output nodeResourceGroup string = aksCluster.properties.nodeResourceGroup
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
