// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.azureactivedirectory/b2cdirectories?pivots=deployment-language-bicep

@description('Specifies the Azure location where the resource should be created.')
#disable-next-line no-unused-params  // HACK because we can't use the location parameter due to missing locations in Azure
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

@description('Is this a production environment?')
param isProduction bool

@description('Country code for the tenant')
param countryCode string = 'GB'

// Note, you cannot update a b2c module, you have to delete it and recreate it. 
@description('Does the b2c directory already exist? If so, we will not create it as it can only be created once.')
param createB2C bool = false

resource b2cDirectory 'Microsoft.AzureActiveDirectory/b2cDirectories@2021-04-01' = if(createB2C) {
  name: '${replace(toLower('b2c${baseNameForResources}'), '-', '')}.onmicrosoft.com'
  #disable-next-line no-hardcoded-location  
  location: 'europe'  // List of available regions for the resource type is 'global,unitedstates,europe,asiapacific,australia,japan'
  tags: tags
  sku: {
    name:  isProduction ? 'Standard' : 'Standard' // 'Standard' or 'Premium' 
    tier: 'A0'
  }
  properties: {
    createTenantProperties: {
      countryCode: countryCode
      displayName: 'b2c-${baseNameForResources}'      
    }
  }
}

output b2cTenantId string = b2cDirectory.id
