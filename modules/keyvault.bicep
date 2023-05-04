// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-bicep

// Based on https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.keyvault/key-vault-secret-create/main.bicep
// alternative interesting version - https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/bicep/KV-KeyVault.bicep
@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

@description('Is this a production environment?')
param isProduction bool

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'get'
  'create'
  'list'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'get'
  'list'
  'update'
  'create'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'


@description('This is the built-in Key Vault Administrator user. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-administrator')
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'mi-${baseNameForResources}'
  location: location
}

@description('This is the built-in Key Vault Administrator role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-administrator')
resource keyVaultAdministratorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-${baseNameForResources}'
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: true
    enableRbacAuthorization: true
    tenantId: subscription().tenantId
    accessPolicies: []
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
  dependsOn:[
    managedIdentity
  ]
}


module roleAssignment 'extensions/keyvault-role-assignment.bicep' = {
  name: 'role-assignment'
  params: {
    keyVaultName: keyVault.name
    roleAssignmentName: guid(keyVault.id, managedIdentity.properties.principalId, keyVaultAdministratorRoleDefinition.id)
    roleDefinitionId: keyVaultAdministratorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
  }
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: managedIdentity.properties.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}
// debug
output  roleAssignmentName string = guid( managedIdentity.properties.principalId, keyVaultAdministratorRoleDefinition.id)
output roleDefinitionId string = keyVaultAdministratorRoleDefinition.id
output principalId string = managedIdentity.properties.principalId

/*

param location string
param baseApplicationName string
param environmentName string
param environmentNumber int
param deployedDate string
param b2cTenantId string
param b2cClientId string
param b2cClientSecret string

var keyVaultName = '${baseApplicationName}-${environmentName}-${environmentNumber}-kv'
var keyVaultSku = 'standard'
var keyVaultPrincipleName = 'key-vault-principle'

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: b2cTenantId
    sku: {
      family: keyVaultSku
      name: keyVaultSku
    }
    accessPolicies: [
      {
        tenantId: b2cTenantId
        objectId: b2cClientId
        permissions: {
          keys: [
            'get'
            'create'
            'delete'
          ]
          secrets: [
            'get'
            'set'
            'delete'
          ]
        }
      }
    ]
  }
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVaultName}-sql-admin-password'
  properties: {
    value: b2cClientSecret
  }
  dependsOn: [
    keyVault
  ]
}

resource keyVaultPrinciple 'Microsoft.KeyVault/vaults/principals@2021-06-01-preview' = {
  name: '${keyVaultName}/${keyVaultPrincipleName}'
  properties: {
    objectId: b2cClientId
    displayName: keyVaultPrincipleName
    roles: [
      {
        roleDefinitionId: 'f3a67aa7-65c7-42a6-84a7-2d784e84a6b0'
        // This is the Key Vault Contributor role
      }
    ]
  }
  dependsOn: [
    keyVault
  ]
}

output keyVaultName string = keyVault.name
output sqlAdminUser string = 'sqladmin'
output sqlAdminPasswordSecret string = keyVaultSecret.id
```

This module creates a Key Vault with a standard SKU, and adds the B2C principle user as a Key Vault administrator with permissions to create, delete, get, set secrets, and keys. It also creates a secret in the Key Vault to store the B2C client secret, and adds the principle user as a Key Vault contributor. The `sqlAdminUser` output is set to `sqladmin`, and the `sqlAdminPasswordSecret` output is set to the ID of the secret created to store the B2C client secret.
*/
