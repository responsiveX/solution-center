targetScope = 'resourceGroup'

param location string = resourceGroup().location

param vNetName string = 'vnet-VmStarterKit'
param vmSubnetName string = 'VMs'

param vmName string = 'vm-01'
param vmSize string = 'Standard_B1s'
param vmAdminUsername string = 'adminadmin'
@secure()
param vmAdminPassword string

param recoveryServicesVaultName string = 'rsv-VmBackupVault'

module vNet 'modules/vnet-with-bastion.bicep' = {
  name: 'vnet-with-bastion'
  params: {
    location: location
    vNetName: vNetName
    vmSubnetName: vmSubnetName
  }
}

module monitoring 'modules/monitoring-infrastructure.bicep' = {
  name: 'monitoring-infrastructure'
  params: {
    location: location
  }
}

resource recoveryVault 'Microsoft.RecoveryServices/vaults@2022-10-01' = {
  name: recoveryServicesVaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

module vm 'modules/virtual-machine-with-backups-and-logging.bicep' = {
  name: 'virtual-machine-${vmName}'
  params: {
    location: location
    vmName: vmName
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
    vmSize: vmSize
    vNetName: vNetName
    vmSubnetName: vmSubnetName
    vmAvailabilityZone: 1
    bootLogStorageAccountName: monitoring.outputs.storageAccountName
    recoveryServicesVaultName: recoveryVault.name
    dataCollectionRuleName: monitoring.outputs.dataCollectionRuleName
  }
  dependsOn: [
    vNet
  ]
}
