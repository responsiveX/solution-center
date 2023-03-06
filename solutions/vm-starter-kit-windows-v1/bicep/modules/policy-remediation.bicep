targetScope = 'resourceGroup'

param backupPolicyDefinitionId string
param backupPolicyAssignmentId string

param monitoringPolicyDefinitionId string
param monitoringPolicyAssignmentId string

resource backupPolicyRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'backup-vmss-remediation'
  scope: resourceGroup()
  properties: {
    policyAssignmentId: backupPolicyAssignmentId
    policyDefinitionReferenceId: backupPolicyDefinitionId
    resourceDiscoveryMode: 'ReEvaluateCompliance'
  }

  // properties: {
  //   failureThreshold: {
  //     percentage: int
  //   }
  //   filters: {
  //     locations: [
  //       'string'
  //     ]
  //   }
  //   parallelDeployments: int
  //   policyAssignmentId: 'string'
  //   policyDefinitionReferenceId: 'string'
  //   resourceCount: int
  //   resourceDiscoveryMode: 'string'
  // }
}

resource monitoringPolicyRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'monitoring-remediation'
  scope: resourceGroup()
  properties: {
    policyAssignmentId: monitoringPolicyAssignmentId
    policyDefinitionReferenceId: monitoringPolicyDefinitionId
    resourceDiscoveryMode: 'ReEvaluateCompliance'
  }
}
