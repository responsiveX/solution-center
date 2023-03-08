targetScope = 'resourceGroup'

// This template distributes the scale set VMs across availability zones. Therefore it is limited to regions with AZ support.
// The list of regions with AZ support is from: https://learn.microsoft.com/en-us/azure/reliability/availability-zones-service-support
@allowed([
  'brazilsouth'
  'canadacentral'
  'centralus'
  'eastus'
  'eastus2'
  'southcentralus'
  'westus2'
  'westus3'
  'francecentral'
  'northeurope'
  'norwayeast'
  'uksouth'
  'westeurope'
  'swedencentral'
  'switzerlandnorth'
  'polandcentral'
  'qatarcentral'
  'uaenorth'
  'southafricanorth'
  'australiaeast'
  'centralindia'
  'japaneast'
  'koreacentral'
  'southeastasia'
  'eastasia'
])
param location string

param bastionName string = 'BastionHost'
param networkName string = 'VmStarterKit'
param vmSubnetName string = 'VMs'

param vmNamePrefix string = 'VM'
param vmSize string = 'Standard_D2s_v5'
param adminUsername string
@secure()
param sshPublicKey string
param osdiskSizeGB int = 30

param recoveryServicesVaultName string = 'rsv-VmBackupVault'
var recoveryVaultPolicyName = 'DefaultPolicy'

param loadBalancerName string = 'lbe-LoadBalancer'
param loadBalancerIpAddressName string = 'pip-LoadBalancer'
var loadBalancerFrontEndName = 'LoadBalancerFrontEnd'
var loadBalancerBackendPoolName = 'LoadBalancerBackEndPool'
var loadBalancerProbeName80 = 'loadBalancerHealthProbePort80'
var loadBalancerProbeName443 = 'loadBalancerHealthProbePort443'

var vmScaleSetName = 'vmss-VmStarterKit'

module vNetModule 'modules/vnet.bicep' = {
  name: 'vnet'
  params: {
    location: location
    networkName: networkName
    vmSubnetName: vmSubnetName
    openWebPorts: true
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
    createDataCollectionRule: false
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

resource recoveryVaultPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-04-01' existing = {
  name: recoveryVaultPolicyName
  parent: recoveryVault
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
        name: 'HTTP'
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
          idleTimeoutInMinutes: 5
          protocol: 'Tcp'
          disableOutboundSnat: true
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, loadBalancerProbeName80)
          }
        }
      }
      {
        name: 'HTTPS'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, loadBalancerFrontEndName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, loadBalancerBackendPoolName)
          }
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          protocol: 'Tcp'
          disableOutboundSnat: true
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, loadBalancerProbeName443)
          }
        }
      }
    ]
    probes: [
      {
        name: loadBalancerProbeName80
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 3
        }
      }
      {
        name: loadBalancerProbeName443
        properties: {
          protocol: 'Tcp'
          port: 443
          intervalInSeconds: 5
          numberOfProbes: 3
        }
      }
    ]
    outboundRules: [
      {
        name: 'AllowOutboundTraffic'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, loadBalancerBackendPoolName)
          }
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, loadBalancerFrontEndName)
            }
          ]
          protocol: 'All'
          enableTcpReset: false
          idleTimeoutInMinutes: 5
          allocatedOutboundPorts: 128
        }
      }
    ]
  }
}

module policiesModule 'modules/backup-and-monitoring-policies.bicep' = {
  name: 'backup-and-monitoring-policies'
  params: {
    location: location
    recoveryVaultPolicyId: recoveryVaultPolicy.id
    logAnalyticsResourceId: monitoringModule.outputs.logAnalyticsWorkspaceId
  }
}

module vmScaleSetModule 'modules/virtual-machine-scale-set.bicep' = {
  name: 'vm-scale-set'
  params: {
    location: location
    vmScaleSetName: vmScaleSetName
    vNetName: vNetModule.outputs.vNetName
    vmSubnetName: vmSubnetName
    loggingStorageUri: monitoringModule.outputs.storageUri
    vmNamePrefix: vmNamePrefix
    vmSize: vmSize
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    osdiskSizeGB: osdiskSizeGB
    loadBalancerName: loadBalancer.name
    loadBalancerBackendPoolName: loadBalancerBackendPoolName
    vmManagedIdentityResourceId: monitoringModule.outputs.vmManagedIdentityResourceId
    amaManagedIdentityResourceId: monitoringModule.outputs.amaManagedIdentityResourceId
  }
}

module policyRemediationModule 'modules/policy-remediation.bicep' = {
  name: 'policy-remediation'
  params: {
    location: location
    backupPolicyAssignmentId: policiesModule.outputs.backupPolicyAssignmentId
    backupPolicyDefinitionId: policiesModule.outputs.backupPolicyDefinitionId
    monitoringPolicyAssignmentId: policiesModule.outputs.monitoringPolicyAssignmentId
    monitoringPolicyDefinitionId: policiesModule.outputs.monitoringPolicyDefinitionId
  }
  dependsOn: [
    vmScaleSetModule
  ]
}
