targetScope = 'resourceGroup'

param location string = resourceGroup().location

param bastionName string = 'BastionHost'
param networkName string = 'VmStarterKit'
param vmSubnetName string = 'VMs'

param vmNamePrefix string = 'VM'
param vmSize string = 'Standard_D2s_v5'
param adminUsername string = 'azureadmin'
@secure()
param sshPublicKey string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDkNiD0HIP68W2cW5hUBfgi7+7l+a9FWX+bSKmbRlEVXXwS+YBL/PfPM2+/InpSqZVCEthxyWQRUJj5zhr8glZQhoKMLA7PdCj4zQ1BhZMUBiEJRhQbjiHpnp+FpntZqIaSEPLhlK0lS0oS9gxZq1V0RUcNzCQmtRn5jnvTYmkBLakRk7sW+VJqHmwZy9C8tmdPRv/9mycG2zSAgEcZR2AB4PMKettfWjwmSgBZySHhlya55xd7YyDZHSJXMrrgneLyH+HdAWxTiODs5rA1YMi6VOfWk6mSF1ox0ssQPFIifXwxoPYTRjz2fBIWefZwqvb/ahyofnsnQFvoEFK+pTvOXTQ6hdMHUqo8AZO/YFcJjN0KsoGrYv2Zb6IzrZ7LLsfGTcMbOqaUk9uTbi5adlPRRf8lx2tRkMvQVInrjDKEmjWq6M4verXfR1gYA8xoTN1Hw/K2JT6v21bUaCFbeGqFkgJc6+INLS/BPGKeAQPHTNExo2dgwghWUwTS6yG6mek= generated-by-azure'
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

module vNetModule 'modules/vnet-with-bastion.bicep' = {
  name: 'vnet-with-bastion'
  params: {
    location: location
    networkName: networkName
    vmSubnetName: vmSubnetName
    bastionName: bastionName
    openWebPorts: true
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

// module policiesModule 'modules/backup-and-monitoring-policies.bicep' = {
//   name: 'backup-and-monitoring-policies'
//   params: {
//     location: location
//     recoveryVaultPolicyId: recoveryVaultPolicy.id
//   }
// }

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
  // dependsOn: [
  //   policiesModule
  // ]
}
