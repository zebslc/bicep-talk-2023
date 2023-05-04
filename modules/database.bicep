// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.sql/servers/databases?pivots=deployment-language-bicep

@description('The name of the environment.  This must be dev, test or prod')
@allowed([
  'dev'
  'test'
  'uat'
  'prod'
])
param environmentName string = 'dev'

@description('Is this the production environment?')
param isProduction bool

@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

var standardSku = {
  name: 'GP_S_Gen5_1'
  tier: 'GeneralPurpose'
  family: 'Gen5'
}

// Make these premium for production
var productionSku = {
  name: 'Standard'
  tier: 'Standard'
  capacity: 200
}

var standardProperties = {
  minCapacity: any('0.5')
  autoPauseDelay: 60
}

var sqlDatabaseSku = isProduction ? productionSku : standardSku
var sqlDatabaseProperties = isProduction ? standardProperties : {}

@description('The name of the storage account SKU.')
param auditStorageAccountSkuName string = 'Standard_LRS'

//@description('The administrator login username for the SQL server.')
var sqlServerAdministratorLogin = '${baseNameForResources}-sqladmin'

var auditingEnabled = environmentName == 'prod'
var auditStorageAccountName = take('bearaudit${location}${uniqueString(resourceGroup().id)}', 24)

var sqlServerName = 'sql-${baseNameForResources}'
var sqlDatabaseName = 'sqldb-${baseNameForResources}'
var sqlServerAdministratorLoginPassword = '${guid(sqlServerAdministratorLogin)}-${take(toLower(guid(sqlServerAdministratorLogin)),5)}$' 

resource creatingSqlServer 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorLoginPassword
  }
}

resource creatingSqlDatabase 'Microsoft.Sql/servers/databases@2022-08-01-preview' = {
  parent: creatingSqlServer
  name: sqlDatabaseName
  location: location
  sku: sqlDatabaseSku
  properties: sqlDatabaseProperties
  tags: tags
}

resource creatingAuditStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = if (auditingEnabled) {
  name: auditStorageAccountName
  location: location
  sku:{
    name: auditStorageAccountSkuName
  }
  kind: 'StorageV2'
}

resource creatingSqlServerAudit 'Microsoft.Sql/servers/auditingSettings@2020-11-01-preview' = if (auditingEnabled) {
  parent: creatingSqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    storageEndpoint: isProduction ? creatingAuditStorageAccount.properties.primaryEndpoints.blob : ''
    storageAccountAccessKey: isProduction ? creatingAuditStorageAccount.listKeys().keys[0].value : ''
  }
}

module storePassword 'extensions/keyvault-storeSecrets.bicep' = {
  name: 'Store-SQL-Password'
  params: {
    baseNameForResources: baseNameForResources
    secretsObject: {
      secrets: [
        {
          secretName: 'sqlAdminPassword'
          secretValue: sqlServerAdministratorLoginPassword
        }
      ]
    }
  }
}
output sqlServerName string = creatingSqlServer.name
output sqlDatabaseName string = creatingSqlDatabase.name
