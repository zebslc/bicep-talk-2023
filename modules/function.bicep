// An individual azure function

// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.web/sites/functions?pivots=deployment-language-bicep
// Based on https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.web/function-http-trigger/main.bicep

@description('Which geographical region will everything be set up in?')
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

@description('The workspace id for the log analytics workspace')
param logWorkspaceId string

@description('The name of this function app')
param functionAppName string

@description('What are the CORS allowed origin')
param allowedOrigins array

// @description('Which hosting plan will this function app be in taken from the appServicePlan module?')
// param serverFarmId string
param appServicePlanName string

@description('The storage account name to use for the function app')
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource serverFarm 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: appServicePlanName
}

// App insights

// Add an addition tag that will refer to the function app
var functionTags = {
  functionApp: functionAppName
}
var totalTags = union(tags, functionTags)
var functionName = '${baseNameForResources}-${functionAppName}'
module moduleAppInsightsForFunction 'appinsights.bicep' = {
  name: 'Create-${functionAppName}-Insights'
  scope: resourceGroup()
  params: {
    location: location
    baseNameForResources: '${baseNameForResources}-${functionAppName}'
    tags: totalTags
    workspaceResourceId: logWorkspaceId
    typeOfInformationBeingRecorded: 'web'
    kindOfAppInsight: 'web'
    uniqueNameOfAppInsight: 'web'
  }
}

resource creatingFunctionApp 'Microsoft.Web/sites@2020-12-01' = {
  name: 'func-${functionName}'
  location: location
  kind: 'functionapp'
  tags: totalTags
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: moduleAppInsightsForFunction.outputs.instrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${moduleAppInsightsForFunction.outputs.instrumentationKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
      cors: {
        allowedOrigins: allowedOrigins
      }
      netFrameworkVersion: '7'
      ftpsState: 'Disabled' 
    }
    httpsOnly: true
  }
  dependsOn: [
    moduleAppInsightsForFunction
    storageAccount
    serverFarm
  ]
}

output functionAppUrl string = creatingFunctionApp.properties.defaultHostName
output functionAppInsightsInstrumentationKey string = moduleAppInsightsForFunction.outputs.instrumentationKey
