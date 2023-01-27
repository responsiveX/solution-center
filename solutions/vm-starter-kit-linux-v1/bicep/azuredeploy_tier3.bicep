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

resource vmScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2022-08-01' = {
  name: vmScaleSetName
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: 3
  }
  properties: {
    singlePlacementGroup: false
    orchestrationMode: 'Flexible'
    platformFaultDomainCount: 1
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
        osDisk: {
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          caching: 'ReadWrite'
          createOption: 'FromImage'
          diskSizeGB: osdiskSizeGB
        }
      }
      networkProfile: {
        networkApiVersion: '2020-11-01'
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetModule.outputs.vNetName, vmSubnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancer.name, loadBalancerBackendPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: vmNamePrefix
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: sshPublicKey
              }
            ]
          }
          provisionVMAgent: true
          patchSettings: {
            patchMode: 'AutomaticByPlatform'
          }
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: monitoringModule.outputs.storageUri
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: 'InstallNginx'
            properties:{
              publisher: 'Microsoft.Azure.Extensions'
              type:'CustomScript'
              typeHandlerVersion: '2.1'
              autoUpgradeMinorVersion: true
              protectedSettings:{
                commandToExecute: 'sudo apt-get update && sudo apt-get install nginx -y && sudo sed -i "s/Welcome to nginx/Welcome to nginx from ${vmNamePrefix}/g" /var/www/html/index.nginx-debian.html'
              }
            }
          }
          {
            name: 'HealthExtension'
            properties: {
              provisionAfterExtensions: [
                'InstallNginx'
              ]
              publisher: 'Microsoft.ManagedServices'
              type: 'ApplicationHealthLinux'
              typeHandlerVersion: '1.0'
              autoUpgradeMinorVersion: true
              settings: {
                protocol: 'http'
                port: 80
                requestPath: 'http://127.0.0.1'
                intervalInSeconds: 5
                numberOfProbes: 1
              }
            }
          }
          {
            name: 'DependencyAgentWindows'
            properties: {
              provisionAfterExtensions: [
                'InstallNginx'
              ]
              publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
              type: 'DependencyAgentLinux'
              typeHandlerVersion: '9.5'
              autoUpgradeMinorVersion: true
              settings: {
                enableAMA: true
              }
            }
          }
          {
            name: 'AzureMonitorLinuxAgent'
            properties: {
              provisionAfterExtensions: [
                'InstallNginx'
              ]
              publisher: 'Microsoft.Azure.Monitor'
              type: 'AzureMonitorLinuxAgent'
              typeHandlerVersion: '1.21'
              autoUpgradeMinorVersion: true
              enableAutomaticUpgrade: true
              settings: {
                authentication: {
                  managedIdentity: {
                    'identifier-name': 'mi_res_id'
                    'identifier-value': monitoringModule.outputs.managedIdentityResourceId
                  }
                }
              }
            }
          }
        ]
      }
    }
  }
}

