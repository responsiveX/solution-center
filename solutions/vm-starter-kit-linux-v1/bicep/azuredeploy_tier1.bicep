targetScope = 'resourceGroup'
param location string = resourceGroup().location

param bastionName string = 'BastionHost'
param networkName string = 'VmStarterKit'

param vmSubnetName string = 'VMs'

param vmName string = 'vm-01'
param vmSize string = 'Standard_D2s_v5'
param ubuntuServerSku string = '22.04-LTS'
param adminUsername string
@secure()
param sshPublicKey string
param osdiskSizeGB int = 30


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

module VM 'modules/virtual-machine-simple.bicep' = {
  name: 'virtual-machine-${vmName}'
  params: {
    location: location
    vmName: vmName
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    vmSize: vmSize
    osdiskSizeGB: osdiskSizeGB
    ubuntuServerSku: ubuntuServerSku
    vNetName: vNetModule.outputs.vNetName
    vmSubnetName: vmSubnetName
  }
}
