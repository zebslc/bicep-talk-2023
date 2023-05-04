// Extension to store key vault secrets

// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-bicep
// More info https://ochzhen.com/blog/key-vault-secrets-as-parameters-azure-bicep

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Specifies all secrets {"secretName":"","secretValue":""} wrapped in a secure object.')
@secure()
param secretsObject object

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: 'kv-${baseNameForResources}'
}

resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = [for secret in secretsObject.secrets: {
  name: secret.secretName
  parent: keyVault
  properties: {
    value: secret.secretValue
  }
}]
