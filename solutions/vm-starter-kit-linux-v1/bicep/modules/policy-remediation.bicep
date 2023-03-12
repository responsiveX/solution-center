targetScope = 'resourceGroup'

param backupPolicyAssignmentId string
param monitoringPolicyAssignmentId string

resource backupPolicyRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: guid('${resourceGroup().id}-${backupPolicyAssignmentId}')
  scope: resourceGroup()
  properties: {
    policyAssignmentId: backupPolicyAssignmentId
    resourceDiscoveryMode: 'ReEvaluateCompliance'
  }
}

resource monitoringPolicyRemediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: guid('${resourceGroup().id}-${monitoringPolicyAssignmentId}')
  scope: resourceGroup()
  properties: {
    policyAssignmentId: monitoringPolicyAssignmentId
    resourceDiscoveryMode: 'ReEvaluateCompliance'
  }
}
