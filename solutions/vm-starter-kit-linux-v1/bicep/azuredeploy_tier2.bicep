targetScope = 'resourceGroup'

param location string = resourceGroup().location

param bastionName string = 'BastionHost'
param networkName string = 'VmStarterKit'

param vmSubnetName string = 'VMs'

param vmName string = 'vm-01'
param vmSize string = 'Standard_D2s_v5'
param adminUsername string = 'azureadmin'
@secure()
param sshPublicKey string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDkNiD0HIP68W2cW5hUBfgi7+7l+a9FWX+bSKmbRlEVXXwS+YBL/PfPM2+/InpSqZVCEthxyWQRUJj5zhr8glZQhoKMLA7PdCj4zQ1BhZMUBiEJRhQbjiHpnp+FpntZqIaSEPLhlK0lS0oS9gxZq1V0RUcNzCQmtRn5jnvTYmkBLakRk7sW+VJqHmwZy9C8tmdPRv/9mycG2zSAgEcZR2AB4PMKettfWjwmSgBZySHhlya55xd7YyDZHSJXMrrgneLyH+HdAWxTiODs5rA1YMi6VOfWk6mSF1ox0ssQPFIifXwxoPYTRjz2fBIWefZwqvb/ahyofnsnQFvoEFK+pTvOXTQ6hdMHUqo8AZO/YFcJjN0KsoGrYv2Zb6IzrZ7LLsfGTcMbOqaUk9uTbi5adlPRRf8lx2tRkMvQVInrjDKEmjWq6M4verXfR1gYA8xoTN1Hw/K2JT6v21bUaCFbeGqFkgJc6+INLS/BPGKeAQPHTNExo2dgwghWUwTS6yG6mek= generated-by-azure'
param osdiskSizeGB int = 30

param recoveryServicesVaultName string = 'rsv-VmBackupVault'


module vNetModule 'modules/vnet.bicep' = {
  name: 'vnet-with-bastion'
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
    sshPublicKey: sshPublicKey
    vmSize: vmSize
    osdiskSizeGB: osdiskSizeGB
    vNetName: vNetModule.outputs.vNetName
    vmSubnetName: vmSubnetName
    bootLogStorageAccountName: monitoringModule.outputs.storageAccountName
    recoveryServicesVaultName: recoveryVault.name
    dataCollectionRuleName: monitoringModule.outputs.dataCollectionRuleName
    vmManagedIdentityResourceId: monitoringModule.outputs.vmManagedIdentityResourceId
    amaManagedIdentityResourceId: monitoringModule.outputs.amaManagedIdentityResourceId
  }
}
