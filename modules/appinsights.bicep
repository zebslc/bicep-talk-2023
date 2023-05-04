// Create an individual app insights instance (called as part of a higher level resource)

// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?pivots=deployment-language-bicep

@description('Which geographical region will everything be set up in?')
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

@description('The id of the logging workspace to use (if any)')
param workspaceResourceId string

@description('What kind of app insight is this?')
param kindOfAppInsight string = 'web'

@description('What type of information is being recorded?')
param typeOfInformationBeingRecorded string

@description('A unique name for the app insight')
param uniqueNameOfAppInsight string

resource creatingAppInsight 'microsoft.insights/components@2020-02-02-preview' = {
  name: 'appi-${baseNameForResources}-${uniqueNameOfAppInsight}'
  location: location
  tags: tags
  properties: {
    Application_Type: typeOfInformationBeingRecorded
    Flow_Type: 'Redfield'
    Request_Source: 'Bicep'
    WorkspaceResourceId: workspaceResourceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  kind: kindOfAppInsight
}

output appInsightId string = creatingAppInsight.id
output instrumentationKey string = creatingAppInsight.properties.InstrumentationKey
output connectionString string = creatingAppInsight.properties.ConnectionString
