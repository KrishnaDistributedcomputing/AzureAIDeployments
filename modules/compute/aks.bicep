// Azure Kubernetes Service Module
// Deploys AKS for AI workload compute

@description('Azure region')
param location string

@description('AKS cluster name')
param clusterName string

@description('Kubernetes version')
param kubernetesVersion string = '1.30'

@description('System node pool VM size')
param systemNodeVmSize string = 'Standard_D4s_v5'

@description('System node pool count')
param systemNodeCount int = 3

@description('AI/GPU node pool VM size')
param aiNodeVmSize string = 'Standard_NC6s_v3'

@description('AI node pool count')
param aiNodeCount int = 0

@description('VNet subnet ID for the AKS nodes')
param subnetId string

@description('Whether to enable Azure RBAC for Kubernetes')
param enableAzureRbac bool = true

@description('Whether to enable private cluster')
param enablePrivateCluster bool = false

@description('Tags')
param tags object = {}

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
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
    aadProfile: enableAzureRbac
      ? {
          managed: true
          enableAzureRBAC: true
        }
      : null
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'calico'
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
    }
    agentPoolProfiles: union(
      [
        {
          name: 'system'
          mode: 'System'
          vmSize: systemNodeVmSize
          count: systemNodeCount
          vnetSubnetID: subnetId
          osType: 'Linux'
          osSKU: 'AzureLinux'
          type: 'VirtualMachineScaleSets'
        }
      ],
      aiNodeCount > 0
        ? [
            {
              name: 'aigpu'
              mode: 'User'
              vmSize: aiNodeVmSize
              count: aiNodeCount
              vnetSubnetID: subnetId
              osType: 'Linux'
              osSKU: 'AzureLinux'
              type: 'VirtualMachineScaleSets'
              nodeLabels: {
                workload: 'ai-inference'
              }
              nodeTaints: [
                'nvidia.com/gpu=present:NoSchedule'
              ]
            }
          ]
        : []
    )
  }
}

@description('AKS cluster resource ID')
output id string = aks.id

@description('AKS cluster name')
output name string = aks.name

@description('AKS cluster FQDN')
output fqdn string = enablePrivateCluster ? aks.properties.privateFQDN : aks.properties.fqdn
