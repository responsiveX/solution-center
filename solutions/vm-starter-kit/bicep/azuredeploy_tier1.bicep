targetScope = 'resourceGroup'

param location string = resourceGroup().location

param vNetName string = 'vnet-VmStarterKit'
param vmSubnetName string = 'VMs'

param vmName string = 'vm-01'
param vmSize string = 'Standard_B1s'
param vmAdminUsername string = 'adminadmin'
@secure()
param vmAdminPassword string

module vNet 'modules/vnet-with-bastion.bicep' = {
  name: 'vnet-with-bastion'
  params: {
    location: location
    vNetName: vNetName
    vmSubnetName: vmSubnetName
  }
}

module VM 'modules/virtual-machine-simple.bicep' = {
  name: 'virtual-machine-${vmName}'
  params: {
    location: location
    vmName: vmName
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
    vmSize: vmSize
    vNetName: vNetName
    vmSubnetName: vmSubnetName
  }
  dependsOn: [
    vNet
  ]
}
