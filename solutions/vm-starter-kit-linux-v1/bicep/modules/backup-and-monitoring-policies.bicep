targetScope = 'resourceGroup'

param location string = resourceGroup().location

param recoveryVaultPolicyId string

param logAnalyticsResourceId string

param backupPolicyName string = 'Backup VMs'
param backupPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/09ce66bc-1220-4153-8104-e3f51c936913'

param monitoringPolicyName string = 'Monitor VMSS'
param monitoringPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/c7f3bf36-b807-4f18-82dc-f480ad713635'

resource backupPolicyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: backupPolicyName
  location: location
  scope: resourceGroup()
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    policyDefinitionId: backupPolicyDefinitionId
    parameters: {
      vaultLocation: {
        value: location
      }
      backupPolicyId: {
        value: recoveryVaultPolicyId
      }
    }
    resourceSelectors: [
      {
        name: 'Resources to be monitored'
         selectors: [
            {
              kind: 'resourceType'
              in: [
                'Microsoft.Compute/virtualMachines'
              ]
            }
         ]
      }
   ]
  }
}

resource monitoringPolicyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: monitoringPolicyName
  location: location
  scope: resourceGroup()
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    policyDefinitionId: monitoringPolicyDefinitionId
    parameters: {
      workspaceResourceId: {
        value: logAnalyticsResourceId
      }
      userGivenDcrName: {
        value: 'ama-vmi-vmss'
      }
      enableProcessesAndDependencies: {
        value: true
      }
    }
    resourceSelectors: [
      {
        name: 'Resources to be monitored'
        selectors: [
            {
              kind: 'resourceType'
              in: [
                'Microsoft.Compute/virtualMachineScaleSets'
              ]
            }
        ]
      }
    ]
  }
}

output backupPolicyDefinitionId string = backupPolicyDefinitionId
output backupPolicyAssignmentId string = backupPolicyAssignment.id
output backupPolicyPrincipalId string = backupPolicyAssignment.identity.principalId
output monitoringPolicyDefinitionId string = monitoringPolicyDefinitionId
output monitoringPolicyAssignmentId string = monitoringPolicyAssignment.id
output monitoringPolicyPrincipalId string = monitoringPolicyAssignment.identity.principalId
