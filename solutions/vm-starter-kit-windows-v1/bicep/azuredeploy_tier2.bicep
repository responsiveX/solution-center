targetScope = 'resourceGroup'

param location string = resourceGroup().location

param bastionName string = 'BastionHost'

param networkName string = 'VmStarterKit'
param vmSubnetName string = 'VMs'

param vmName string = 'vm-01'
param vmSize string = 'Standard_D2s_v5'
param adminUsername string = 'azureadmin'
@secure()
param adminPassword string = 'P@ssword4242'

param recoveryServicesVaultName string = 'rsv-VmBackupVault'

module vNetModule 'modules/vnet.bicep' = {
  name: 'vnet'
  params: {
    location: location
    networkName: networkName
    vmSubnetName: vmSubnetName
  }
}

module bastionModule 'modules/bastion.bicep' = {
  name: 'bastion'
  params: {
    location: location
    bastionName: bastionName
    vNetName: vNetModule.outputs.vNetName
    bastionSubnetName: vNetModule.outputs.bastionSubnetName
  }
}

module monitoringModule 'modules/monitoring-infrastructure.bicep' = {
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
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    vNetName: vNetModule.outputs.vNetName
    vmSubnetName: vmSubnetName
    bootLogStorageAccountName: monitoringModule.outputs.storageAccountName
    recoveryServicesVaultName: recoveryVault.name
    dataCollectionRuleName: monitoringModule.outputs.dataCollectionRuleName
    vmManagedIdentityResourceId: monitoringModule.outputs.vmManagedIdentityResourceId
    amaManagedIdentityResourceId: monitoringModule.outputs.amaManagedIdentityResourceId
  }
}
