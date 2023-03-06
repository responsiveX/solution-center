targetScope = 'resourceGroup'

param location string = resourceGroup().location

param recoveryVaultPolicyId string

param logAnalyticsResourceId string

param backupPolicyName string = 'Backup VMs'
param backupPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/09ce66bc-1220-4153-8104-e3f51c936913'

param monitoringPolicyName string = 'Monitor VMs'
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
  }
}

resource virtualMachineContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
}

resource vmContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${backupPolicyName}-windows-vmcontributor')
  properties: {
    principalId: backupPolicyAssignment.identity.principalId
    roleDefinitionId: virtualMachineContributorRole.id
  }
}

resource backupContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e467623-bb1f-42f4-a55d-6e525e11384b'
}

resource backupContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${backupPolicyName}-windows-backupcontributor')
  properties: {
    principalId: backupPolicyAssignment.identity.principalId
    roleDefinitionId: backupContributorRole.id
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
  }
}

resource monitoringContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
}

resource monitoringContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${monitoringPolicyName}-windows-monitoringcontributor')
  properties: {
    principalId: monitoringPolicyAssignment.identity.principalId
    roleDefinitionId: monitoringContributorRole.id
  }
}

resource logAnalyticsContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '92aaf0da-9dab-42b6-94a3-d43ce8d16293'
}

resource logAnalyticsContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${monitoringPolicyName}-windows-loganalyticscontributor')
  properties: {
    principalId: monitoringPolicyAssignment.identity.principalId
    roleDefinitionId: logAnalyticsContributorRole.id
  }
}

output backupPolicyDefinitionId string = backupPolicyDefinitionId
output backupPolicyAssignmentId string = backupPolicyAssignment.id
output monitoringPolicyDefinitionId string = monitoringPolicyDefinitionId
output monitoringPolicyAssignmentId string = monitoringPolicyAssignment.id
