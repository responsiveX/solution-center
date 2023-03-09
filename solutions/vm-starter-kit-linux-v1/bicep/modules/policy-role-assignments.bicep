targetScope = 'resourceGroup'

param backupPolicyPrincipalId string

param monitoringPolicyPrincipalId string

resource virtualMachineContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
}

resource vmContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${resourceGroup().id}-${backupPolicyPrincipalId}-vmcontributor')
  properties: {
    principalId: backupPolicyPrincipalId
    roleDefinitionId: virtualMachineContributorRole.id
    principalType: 'ServicePrincipal'
  }
}

resource backupContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '5e467623-bb1f-42f4-a55d-6e525e11384b'
}

resource backupContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${resourceGroup().id}-${backupPolicyPrincipalId}-backupcontributor')
  properties: {
    principalId: backupPolicyPrincipalId
    roleDefinitionId: backupContributorRole.id
    principalType: 'ServicePrincipal'
  }
}

resource monitoringContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
}

resource monitoringContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${resourceGroup().id}-${monitoringPolicyPrincipalId}-monitoringcontributor')
  properties: {
    principalId: monitoringPolicyPrincipalId
    roleDefinitionId: monitoringContributorRole.id
    principalType: 'ServicePrincipal'
  }
}

resource logAnalyticsContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '92aaf0da-9dab-42b6-94a3-d43ce8d16293'
}

resource logAnalyticsContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${resourceGroup().id}-${monitoringPolicyPrincipalId}-loganalyticscontributor')
  properties: {
    principalId: monitoringPolicyPrincipalId
    roleDefinitionId: logAnalyticsContributorRole.id
    principalType: 'ServicePrincipal'
  }
}
