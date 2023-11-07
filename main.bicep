// Use this as a basic example for creating your own infrastructure as code
// I have added links to the relevant documentation for each resource to help you 
// adjust it to match your own requirements.
// Please look at the Readme.md file for more information on how to run the file.

// As with anything all risks are your own and if in doubt check with a security expert
// and your own company policies before deploying anything to production.

@description('Which geographical region will everything be set up in?')
@allowed([
  'uksouth'
  'ukwest'  
])
param location string = 'uksouth'

@maxLength(10)
@description('The base name of the application.')
param baseApplicationName string = 'shiftleft' // change this to match your own application name or it will fail if someone else has already used it

@description('The name of the environment. This must be dev, test, or prod.')
@allowed([
  'dev'
  'test'
  'uat'
  'prod'
])
param environmentName string = 'dev'

@description('Which environment number will this be set up as')
@minValue(1)
@maxValue(3)
param environmentNumber int = 1

@description('When was this set first deployed?  Note this has to be a parameter because UTCNow is not allowed inside a module.')
param deployedDate string = utcNow('d')

@description('The country code for the country this is being set up in.  This is used for b2c phone number verification.')
@allowed([
  'GB'
])
param countryCode string = 'GB'

@description('Should we create a b2c tenant? This can only be created once after which it has to be updated or deleted.') // set by deployment script https://ochzhen.com/blog/check-if-resource-exists-azure-bicep
param createB2C bool = false

@description('Create a database?')
param createDatabase bool = false

@description('Create a keyvault? Note this will happen automatically if you create a database or b2c tenant.')
param createKeyVault bool = false


@description('Create a static website for holding an Angular site?')
param createStaticWebsite bool = false

@description('A list of services that will be created in this environment')
param servicesToCreate array = [
  'BicepApi'
  'AnotherApi'
]

// Pre-calculated values
@description('Pre-calculate if this is the production environment')
var isProduction = environmentName == 'prod'

@description('Default tags set up')
var tags = {
  Environment: environmentName
  LastDeployed: deployedDate
  ApplicationName: baseApplicationName
  EnvironmentNumber: any(environmentNumber)
  IsProduction: any(isProduction)
}

// Some resource names allow dashes, others like storage don't and are limited to 24 characters
var simpleNameForResources = isProduction ? '${baseApplicationName}${environmentName}' : '${baseApplicationName}${environmentName}${padLeft(environmentNumber,2,'0')}'
var standardNameForResources = isProduction ? '${baseApplicationName}-${environmentName}' : '${baseApplicationName}-${environmentName}-${padLeft(environmentNumber,2,'0')}'

// Set up the resource which everything else depends on
var resourceGroupName = 'rg-${standardNameForResources}'

// Initial resource group
targetScope = 'subscription'
resource deploymentResourceGroup  'Microsoft.Resources/resourceGroups@2022-09-01' = {  
  name: resourceGroupName
  location: location
  tags: tags
}

module createdStorageModule 'modules/storage.bicep' = {
  name: 'Create-BaseStorageDevice'
  scope: deploymentResourceGroup
  params: {
    location: location
    baseNameForResources: simpleNameForResources
    tags: tags
  }  
}

// Log workspace for app insights
module logWorkspace 'modules/logWorkspace.bicep' = {
  name: 'Create-AppInsightsLogWorkspace'
  scope: deploymentResourceGroup
  params: {
    location: location
    baseNameForResources: standardNameForResources
    tags: tags
    isProduction: isProduction
  }
}

// Create key vault for secrets
module keyVault 'modules/keyvault.bicep' = if(createKeyVault || createDatabase) {
  name: 'Create-KeyVault'
  scope: deploymentResourceGroup
  params: {
    location: location
    baseNameForResources: standardNameForResources
    tags: tags
    isProduction: isProduction
  }
}

// Set up the database and store the password in key vault
module database 'modules/database.bicep' = if(createDatabase) {
  name: 'Create-Database'
  scope: deploymentResourceGroup
  params: {
    location: location
    environmentName: environmentName
    isProduction: isProduction
    tags: tags
    baseNameForResources: standardNameForResources
  }
  dependsOn: [
    createdStorageModule
    logWorkspace
    keyVault
  ]
}

// Create the b2c tenant - note in Azure portal, choose directories against your subscription and then choose the b2c tenant to see accounts etc
// It creates a tenant resource within your resource group but to interact with b2c switch directories 
module b2c 'modules/b2c.bicep' = if(createB2C) {
  name: 'Create-B2C'
  scope: deploymentResourceGroup
  params: {
    location: location
    baseNameForResources: simpleNameForResources
    tags: tags
    isProduction: isProduction
    countryCode: countryCode
    createB2C: createB2C
  }
}

// Add Static Web App and app insights for it
module staticWebsite 'modules/staticWebsite.bicep'= if(createStaticWebsite) {
  name: 'Create-StaticWebsite'
  scope: deploymentResourceGroup
  params: {
    location: location
    baseNameForResources: standardNameForResources
    tags: tags
    isProduction: isProduction
    logWorkspaceId: logWorkspace.outputs.createdWorkspaceId
  }
  dependsOn: [
    logWorkspace
    createdStorageModule
  ]
}

// Create all the function apps (using consumption plan because it is cheap and can scale nicely)
module functionsApp 'modules/functions.bicep' = {
  name: 'Create-FunctionsApps'
  scope: deploymentResourceGroup
  params: {
    location: location
    baseNameForResources: standardNameForResources
    tags: tags
    isProduction: isProduction
    environmentName: environmentName
    logWorkspaceId: logWorkspace.outputs.createdWorkspaceId
    storageAccountName: createdStorageModule.outputs.storageAccountName
    services: servicesToCreate
  }
  dependsOn: [
    logWorkspace
    createdStorageModule
  ]
}


// Output all the things we created so the pipeline can pick them up
output createdResourceGroupName string = deploymentResourceGroup.name
output createdStorageAccountName string = createdStorageModule.outputs.storageAccountName
output createdLogWorkspaceId string = logWorkspace.outputs.createdWorkspaceId
output createdAppInsightsInstrumentationKeyForStaticWebsite string = staticWebsite.outputs.appInsightsInstrumentationKeyForStaticWebsite
output createdFunctionsApps array = functionsApp.outputs.createdFunctionApps
output b2cCreated bool = createB2C


