targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('VM administrator username.')
param adminUsername string

@secure()
@description('VM administrator password.')
param adminPassword string

@description('Deploy a Windows Server VM.')
param deployWindowsVm bool = true

@description('Deploy an Ubuntu Linux VM.')
param deployLinuxVm bool = false

@description('Create an extra managed disk for optional disk-backup walkthroughs.')
param deployDiskBackup bool = false

@description('Tags applied to resources.')
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-backup-demo-workload'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'DenyInboundFromInternet'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'vnet-backup-demo'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.70.0.0/16'
      ]
    }
  }
}

resource workloadSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = {
  parent: virtualNetwork
  name: 'snet-workload'
  properties: {
    addressPrefix: '10.70.1.0/24'
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource windowsNic 'Microsoft.Network/networkInterfaces@2024-01-01' = if (deployWindowsVm) {
  name: 'nic-vm-win-backup-demo-01'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: workloadSubnet.id
          }
        }
      }
    ]
  }
}

resource linuxNic 'Microsoft.Network/networkInterfaces@2024-01-01' = if (deployLinuxVm) {
  name: 'nic-vm-linux-backup-demo-01'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: workloadSubnet.id
          }
        }
      }
    ]
  }
}

resource windowsVm 'Microsoft.Compute/virtualMachines@2024-07-01' = if (deployWindowsVm) {
  name: 'vm-win-backup-demo-01'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'winbackup01'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 64
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: windowsNic.id
        }
      ]
    }
  }
}

resource linuxVm 'Microsoft.Compute/virtualMachines@2024-07-01' = if (deployLinuxVm) {
  name: 'vm-linux-backup-demo-01'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'linuxbackup01'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 64
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: linuxNic.id
        }
      ]
    }
  }
}

resource optionalDisk 'Microsoft.Compute/disks@2024-03-02' = if (deployDiskBackup) {
  name: 'disk-backup-demo-optional-01'
  location: location
  tags: tags
  sku: {
    name: 'StandardSSD_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 64
  }
}

@description('Windows VM name, if deployed.')
output windowsVmName string = deployWindowsVm ? windowsVm.name : ''

@description('Linux VM name, if deployed.')
output linuxVmName string = deployLinuxVm ? linuxVm.name : ''

@description('Optional managed disk resource ID, if deployed.')
output optionalDiskId string = deployDiskBackup ? optionalDisk.id : ''
