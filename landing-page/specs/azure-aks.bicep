// Azure Kubernetes Service - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-09-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'compute-orchestration'
}

@description('AKS cluster name prefix')
param clusterPrefix string = 'aks'

@description('Kubernetes version')
param kubernetesVersion string = '1.30.0'

@description('System node count')
param systemNodeCount int = 3

@description('Enable private API server')
param enablePrivateCluster bool = true

var clusterName = '${clusterPrefix}-${environment}-${uniqueString(resourceGroup().id)}'

resource aks 'Microsoft.ContainerService/managedClusters@${apiVersion}' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: clusterName
    enableRBAC: true
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      networkPolicy: 'azure'
    }
    agentPoolProfiles: [
      {
        name: 'systemnp'
        mode: 'System'
        vmSize: 'Standard_D4s_v5'
        count: systemNodeCount
        osType: 'Linux'
        osDiskSizeGB: 128
        type: 'VirtualMachineScaleSets'
      }
    ]
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      defender: {
        securityMonitoring: {
          enabled: true
        }
      }
    }
  }
}

output aksId string = aks.id
output aksName string = aks.name
output principalId string = aks.identity.principalId
