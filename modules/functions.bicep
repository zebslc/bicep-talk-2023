// This file contains a list of all the functions that will be created in this environment
// It will change as you create new resources in your application.  Just add new api names to the list
// and the script will create the function app and app insights for you

// https://markheath.net/post/azure-functions-bicep
// https://github.com/Azure/bicep/blob/main/docs/examples/101/function-app-create/main.bicep

@description('Which geographical region will everything be set up in?')
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

@description('Is this a production environment?')
param isProduction bool

@description('Environment name (prod, uat, test, dev) for origins')
param environmentName string

@description('Storage account name')
param storageAccountName string

@description('The workspace id for the log analytics workspace')
param logWorkspaceId string

// A list of services that will be created in this environment
// Add to this list as you create new services

@description('A list of services that will be created in this environment')
param services array = ['service1', 'service2', 'service3']

// A list of origins that are allowed to call the function apps
var allowedOrigins = {
  prod: [
    'https://functions.azure.com'
    'https://functions-staging.azure.com'
    'https://functions-next.azure.com'
    'https://app.$(baseApplicationName).online'
    'https://$(baseApplicationName)-client-prod.azurewebsites.net'
  ]
  uat: [
    'https://functions.azure.com'
    'https://functions-staging.azure.com'
    'https://functions-next.azure.com'
    'https://app.$(baseApplicationName)-uat.online'
    'https://$(baseApplicationName)-client-uat.azurewebsites.net'
  ]
  test: [
    'https://functions.azure.com'
    'https://functions-staging.azure.com'
    'https://functions-next.azure.com'
    'http://localhost:4200'
    'https://$(baseApplicationName)-client-test-1.azurewebsites.net'
    'https://$(baseApplicationName)-client-test-2.azurewebsites.net'
    'https://$(baseApplicationName)-client-test-3.azurewebsites.ne'
  ]
  dev: [
    'https://functions.azure.com'
    'https://functions-staging.azure.com'
    'https://functions-next.azure.com'
    'http://localhost:4200'
    'https://$(baseApplicationName)-client-dev-1.azurewebsites.net'
    'https://$(baseApplicationName)-client-dev-2.azurewebsites.net'
    'https://$(baseApplicationName)-client-dev-3.azurewebsites.net'
  ]
}

var environmentOrigins = [
  'https://$(baseApplicationName)-client-$(environmentName)-$(environmentNumber).azurewebsites.net'
]

var completeOrigins = concat(allowedOrigins[environmentName], environmentOrigins)

module moduleCreateFunctionAppServicePlan 'appServicePlan.bicep' = {
  name: 'Create-FunctionAppService'
  scope: resourceGroup()
  params: {
    location: location
    baseNameForResources: baseNameForResources
    tags: tags
    isDynamic: true
    isProduction: isProduction
    uniqueName: 'functionAppServicePlan'
  }
}

// Create the function apps for all the services in the list
module moduleCreateFunctionApp 'function.bicep' = [for functionAppName in services:{
  name: 'Create-${functionAppName}-FunctionApp'
  scope: resourceGroup()
  params: {
    location: location
    baseNameForResources: baseNameForResources
    tags: tags
    logWorkspaceId: logWorkspaceId
    storageAccountName: storageAccountName
    functionAppName: functionAppName
    allowedOrigins: completeOrigins
    appServicePlanName: moduleCreateFunctionAppServicePlan.outputs.servicePlanName
  }
  dependsOn: [
    moduleCreateFunctionAppServicePlan
  ]
}]
output createdFunctionApps array = [for i in range(0, length(services)): {
  functionAppInsightsKey: moduleCreateFunctionApp[i].outputs.functionAppInsightsInstrumentationKey
  functionAppUrl: moduleCreateFunctionApp[i].outputs.functionAppUrl
}]

