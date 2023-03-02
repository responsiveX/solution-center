targetScope = 'resourceGroup'

param location string = resourceGroup().location

param recoveryVaultPolicyId string

param backupPolicyName string = 'Backup VMs'
param backupPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/09ce66bc-1220-4153-8104-e3f51c936913'

param monitoringPolicyName string = 'Monitor VMs'
param monitoringPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/4efbd9d8-6bc6-45f6-9be2-7fe9dd5d89ff'

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
