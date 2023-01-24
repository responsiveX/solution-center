targetScope = 'resourceGroup'

param location string = resourceGroup().location

param vNetName string = 'vnet-VmStarterKit'
param vmSubnetName string = 'VMs'

param vmNames array = [
  'vm-01'
  'vm-02'
]
param vmSize string = 'Standard_B2s'
param vmAdminUsername string = 'adminadmin'
@secure()
param vmAdminPassword string

param recoveryServicesVaultName string = 'rsv-VmBackupVault'

param loadBalancerName string = 'lbe-LoadBalancer'
param loadBalancerIpAddressName string = 'pip-LoadBalancer'
var loadBalancerFrontEndName = 'LoadBalancerFrontEnd'
var loadBalancerBackendPoolName = 'LoadBalancerBackEndPool'
var loadBalancerProbeName = 'loadBalancerHealthProbe'

module vNet 'modules/vnet-with-bastion.bicep' = {
  name: 'vnet-with-bastion'
  params: {
    location: location
    vNetName: vNetName
    vmSubnetName: vmSubnetName
    openPort80: true
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

resource loadBalancerPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: loadBalancerIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2021-08-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancerFrontEndName
        properties: {
          publicIPAddress: {
            id: loadBalancerPublicIp.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: loadBalancerBackendPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'Rule-HTTP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, loadBalancerFrontEndName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, loadBalancerBackendPoolName)
          }
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 15
          protocol: 'Tcp'
          enableTcpReset: true
          loadDistribution: 'Default'
          disableOutboundSnat: true
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, loadBalancerProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: loadBalancerProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

module vms 'modules/virtual-machine-with-backups-and-logging.bicep' = [for (vmName, vmIndex) in vmNames: {
  name: 'virtual-machine-${vmName}'
  params: {
    location: location
    vmName: vmName
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
    vmSize: vmSize
    vNetName: vNetName
    vmSubnetName: vmSubnetName
    vmAvailabilityZone: ((vmIndex) % 3) + 1
    bootLogStorageAccountName: monitoring.outputs.storageAccountName
    recoveryServicesVaultName: recoveryVault.name
    dataCollectionRuleName: monitoring.outputs.dataCollectionRuleName
    loadBalancerBackendPoolId: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancer.name, loadBalancerBackendPoolName)
  }
  dependsOn: [
    vNet
  ]
}]

resource iis 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for vmName in vmNames: {
  name: '${vmName}/InstallWebServer'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.7'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
    }
  }
  dependsOn: [
    vms
  ]
}]
