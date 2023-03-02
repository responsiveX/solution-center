targetScope = 'resourceGroup'

param location string = resourceGroup().location

param recoveryVaultPolicyId string

param backupPolicyName string = 'Backup VMs'
param backupPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/09ce66bc-1220-4153-8104-e3f51c936913'

param monitoringPolicyName string = 'Monitor VMs'
param monitoringPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/56a3e4f8-649b-4fac-887e-5564d11e8d3a'

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
  }
}
