targetScope = 'resourceGroup'

param location string = resourceGroup().location

param bastionName string

param vNetName string
param bastionSubnetName string

var bastionHostName = 'bas-${bastionName}'
var bastionIpAddressName = 'pip-${bastionName}'

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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, bastionSubnetName)
          }
        }
      }
    ]
  }
}
