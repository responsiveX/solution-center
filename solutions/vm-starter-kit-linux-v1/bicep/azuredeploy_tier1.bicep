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
    sshPublicKey: sshPublicKey
    vmSize: vmSize
    osdiskSizeGB: osdiskSizeGB
    vNetName: vNetModule.outputs.vNetName
    vmSubnetName: vmSubnetName
  }
}




// var vNetAddressPrefix = '10.1.0.0/16'
// var bastionSubnetAddressPrefix = '10.1.0.0/24'
// var vmSubnetAddressPrefix = '10.1.1.0/24'

// var bastionHostName = 'bas-BastionHost'
// var bastionIpAddressName = 'pip-BastionHost'

// var nsgName = 'nsg-subnet-${vmSubnetName}'
// var bastionSubnetName = 'AzureBastionSubnet'

// resource nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
//   name: nsgName
//   location: location
// }

// resource vNet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
//   name: vNetName
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: [
//         vNetAddressPrefix
//       ]
//     }
//     subnets: [
//       {
//         name: bastionSubnetName
//         properties: {
//           addressPrefix: bastionSubnetAddressPrefix
//           privateEndpointNetworkPolicies: 'Disabled'
//         }
//       }
//       {
//         name: vmSubnetName
//         properties: {
//           addressPrefix: vmSubnetAddressPrefix
//           privateEndpointNetworkPolicies: 'Disabled'
//           networkSecurityGroup: {
//             id: nsg.id
//           }
//         }
//       }
//     ]
//   }
// }

// Setup Bastion for secure VM access

// resource bastionHostPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
//   name: bastionIpAddressName
//   location: location
//   sku: {
//     name: 'Standard'
//   }
//   properties: {
//     publicIPAddressVersion: 'IPv4'
//     publicIPAllocationMethod: 'Static'
//     idleTimeoutInMinutes: 4
//   }
// }

// resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = {
//   name: bastionHostName
//   location: location
//   sku: {
//     name: 'Basic'
//   }
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig01'
//         properties: {
//           privateIPAllocationMethod: 'Dynamic'
//           publicIPAddress: {
//             id: bastionHostPublicIp.id
//           }
//           subnet: {
//             id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, bastionSubnetName)
//           }
//         }
//       }
//     ]
//   }
// }








// Create VM with virtual Network Interface Card

// resource nic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
//   name: '${vmName}-nic'
//   location: location
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig'
//         properties: {
//           primary: true
//           privateIPAllocationMethod: 'Dynamic'
//           subnet: {
//             id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetModule.outputs.vNetName, vmSubnetName)
//           }
//         }
//       }
//     ]
//     enableIPForwarding: false
//   }
// }

// resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
//   name: vmName
//   location: location
//   properties: {
//     hardwareProfile: {
//       vmSize: vmSize
//     }
//     osProfile: {
//       computerName: vmName
//       adminUsername: adminUserName
//       linuxConfiguration: {
//         disablePasswordAuthentication: true
//         ssh: {
//           publicKeys: [
//             {
//               path: '/home/${adminUserName}/.ssh/authorized_keys'
//               keyData: sshPublicKey
//             }
//           ]
//         }
//       }
//     }
//     storageProfile: {
//       imageReference: {
//         publisher: 'Canonical'
//         offer: 'UbuntuServer'
//         sku: '18.04-LTS'
//         version: 'latest'
//       }
//       osDisk: {
//         name: '${vmName}-osdisk'
//         managedDisk: {
//           storageAccountType: 'Standard_LRS'
//         }
//         caching: 'ReadWrite'
//         createOption: 'FromImage'
//         diskSizeGB: osdiskSizeGB
//       }
//     }
//     networkProfile: {
//       networkInterfaces: [
//         {
//           id: nic.id
//         }
//       ]
//     }
//   }
// }
