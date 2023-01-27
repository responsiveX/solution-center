targetScope = 'resourceGroup'

param location string = resourceGroup().location

param networkName string = 'VmStarterKit'

param vmSubnetName string = 'VMs'

param bastionName string = 'BastionHost'

param openWebPorts bool = false

var vNetName = 'vnet-${networkName}'

var vNetAddressPrefix = '10.1.0.0/16'
var bastionSubnetAddressPrefix = '10.1.0.0/24'
var vmSubnetAddressPrefix = '10.1.1.0/24'

var bastionHostName = 'bas-${bastionName}'
var bastionIpAddressName = 'pip-${bastionName}'

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

resource bastionHostPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: bastionIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = {
  name: bastionHostName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig01'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionHostPublicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, bastionSubnetName)
          }
        }
      }
    ]
  }
}

output vNetName string = vNet.name
