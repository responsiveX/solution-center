targetScope = 'resourceGroup'

param location string = resourceGroup().location

param recoveryVaultPolicyId string

param backupPolicyName string = 'Backup VMs'
param backupPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/09ce66bc-1220-4153-8104-e3f51c936913'

param monitoringPolicyName string = 'Monitor VMs'
param monitoringPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/59c3d93f-900b-4827-a8bd-562e7b956e7c'

resource backupPolicy 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
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

resource monitoringPolicy 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: monitoringPolicyName
  location: location
  scope: resourceGroup()
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    policyDefinitionId: monitoringPolicyDefinitionId
    parameters: {
      bringYourOwnUserAssignedManagedIdentity: {
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
