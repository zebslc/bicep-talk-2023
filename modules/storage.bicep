// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep

@description('Which geographical region will everything be set up in?')
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

// Storage account names cannot have dashes, or uppercase letters
var resourceName = replace(toLower('stg${baseNameForResources}'), '-', '')

resource createStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: resourceName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
output primaryBlobEndpoint string = createStorage.properties.primaryEndpoints.blob
output storageAccountId string = createStorage.id
output storageAccountName string = createStorage.name
output storageAccountApiVersion string = createStorage.apiVersion
