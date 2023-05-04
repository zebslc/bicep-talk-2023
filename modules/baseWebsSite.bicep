// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.web/sites?pivots=deployment-language-bicep

@description('Which geographical region will everything be set up in?')
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object = {}

@description('The name of the storage account to use')
param storageAccountName string

@description('The id of the app service plan to use')
param appServicePlanId string

@description('A string that can be added to make this a unique instance')
param appServicePlanIndividualName string

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource creatingAppServicePlan 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-${baseNameForResources}-${appServicePlanIndividualName}'
  location: location
  kind: 'functionapp'
  properties: {
      serverFarmId: appServicePlanId
      clientAffinityEnabled: false
      httpsOnly: true
      siteConfig: {
        appSettings: [
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: 'node'
          }
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
          }
          {            
            name: 'AzureWebJobsStorage'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${existingStorageAccount.listKeys().keys[0].value}'
          }
        ]
    }
  }
  tags: tags
  dependsOn: [
    existingStorageAccount
  ]
}
output appServicePlanName string = creatingAppServicePlan.name
