targetScope = 'resourceGroup'

param location string = resourceGroup().location

param networkName string = 'VmStarterKit'

param vmSubnetName string = 'VMs'

param openWebPorts bool = false

var vNetName = 'vnet-${networkName}'

var vNetAddressPrefix = '10.1.0.0/16'
var bastionSubnetAddressPrefix = '10.1.0.0/24'
var vmSubnetAddressPrefix = '10.1.1.0/24'

var nsgName = 'nsg-subnet-${vmSubnetName}'
var bastionSubnetName = 'AzureBastionSubnet'

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: openWebPorts == false ? [] : [
      {
        name: 'AllowHttpInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHttpsInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vNet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

output vNetName string = vNet.name
output bastionSubnetName string = bastionSubnetName
