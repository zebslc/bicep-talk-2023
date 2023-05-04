// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.web/staticsites?pivots=deployment-language-bicep

@description('Which geographical region will everything be set up in?')
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

@description('Is this a production environment?')
param isProduction bool

@description('The workspace id for the log analytics workspace')
param logWorkspaceId string

var skuName = isProduction ? 'Standard' :  'Free'
var skuTier = isProduction ? 'Standard' :  'Free'
var enterpriseGradeCdnStatus = isProduction ? 'Enabled' :  'Disabled'

module staticAppService 'appServicePlan.bicep' = {
  name: 'Create-StaticAppService'
  scope: resourceGroup()
  params: {
    location: location
    baseNameForResources: baseNameForResources
    tags: tags
    isDynamic: false
    isProduction: isProduction
    uniqueName: 'staticWebsiteServicePlan'
  }
}

// Create the static site
resource createdStaticWebsite 'Microsoft.Web/staticSites@2022-09-01' = {
  name: 'stapp-${baseNameForResources}'
  #disable-next-line no-hardcoded-location
  location: 'centralus' // Hardcoded as location not currently supported in the uk
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    provider: 'None'
    enterpriseGradeCdnStatus: enterpriseGradeCdnStatus
  }
  dependsOn: [staticAppService]
}

// Create an app insight instance that can be linked at deploy time
module moduleCreateStaticWebAppInsights 'appinsights.bicep' = {
  name: 'Create-StaticWebsite-Insights'
  scope: resourceGroup()
  params: {
    location: location
    baseNameForResources: baseNameForResources
    tags: tags
    workspaceResourceId: logWorkspaceId
    typeOfInformationBeingRecorded: 'web'
    kindOfAppInsight: 'web'
    uniqueNameOfAppInsight: 'web'
  }
  dependsOn: [createdStaticWebsite]
}

output appInsightsInstrumentationKeyForStaticWebsite string = moduleCreateStaticWebAppInsights.outputs.instrumentationKey
