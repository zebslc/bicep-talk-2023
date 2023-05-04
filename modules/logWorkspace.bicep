@description('Which geographical region will everything be set up in?')
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

@description('Is this a production environment?')
param isProduction bool

var sku = isProduction ? 'Standard' :  'pergb2018'

resource creatingAppInsightsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${baseNameForResources}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}
output createdWorkspaceId string = creatingAppInsightsWorkspace.id
