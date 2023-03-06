targetScope = 'resourceGroup'

param location string = resourceGroup().location

param storageAccountName string = 'stvmlogs${uniqueString(resourceGroup().id)}'

param logAnalyticsWorkspaceName string = 'log-VmInsights'
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param logAnalyticsSku string = 'PerGB2018'
param logAnalyticsRetentionInDays int = 30
param dataCollectionRuleName string = 'dcr-VmInsights'
var vmInsightsName = 'VMInsights(${logAnalyticsWorkspaceName})'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: logAnalyticsRetentionInDays
  }
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: dataCollectionRuleName
  location: location
  properties: {
    description: 'Data collection rule for VM Insights'
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
        }
      ]
      extensions: [
        {
          streams: [
            'Microsoft-ServiceMap'
          ]
          extensionName: 'DependencyAgent'
          name: 'DependencyAgentDataSource'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspace.id
          name: 'VMInsightsPerf-Logs-Dest'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
      {
        streams: [
          'Microsoft-ServiceMap'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }
}

resource vmInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: vmInsightsName
  location: location
  plan: {
    name: vmInsightsName
    product: 'OMSGallery/VMInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource vmManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-StarterKitVMs'
  location: location
}

resource amaManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-AzureMonitorAgent'
  location: location
}

output storageAccountName string = storageAccount.name
output storageUri string = storageAccount.properties.primaryEndpoints.blob
output dataCollectionRuleName string = dataCollectionRule.name
output vmManagedIdentityResourceId string = vmManagedIdentity.id
output amaManagedIdentityResourceId string = amaManagedIdentity.id
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
