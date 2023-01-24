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


// Create Virtual Network (vNet) with 2 Subnets and Network Security Group (NSG)
// The first subnet is needed for Bastion
// The second subnet will contain the VM(s)
// The NSG is associated with the VM subnet and can be used to secure inbound and outbound communication
module vNetModule 'modules/vnet-with-bastion.bicep' = {
  name: 'vnet-with-bastion'
  params: {
    location: location
    networkName: networkName
    vmSubnetName: vmSubnetName
    bastionName: bastionName
  }
}

module VM 'modules/virtual-machine-simple.bicep' = {
  name: 'virtual-machine-${vmName}'
  params: {
    location: location
    vmName: vmName
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    vNetName: vNetModule.outputs.vNetName
    vmSubnetName: vmSubnetName
  }
}
