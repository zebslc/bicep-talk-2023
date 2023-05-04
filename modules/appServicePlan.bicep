// Configuration Info
// https://learn.microsoft.com/en-us/azure/templates/microsoft.web/serverfarms?pivots=deployment-language-bicep

@description('Which geographical region will everything be set up in?')
param location string

@description('What will be the base name for all resources?')
param baseNameForResources string

@description('Default tags set up')
param tags object

@description('Is this a production environment?')
param isProduction bool

@description('Is this a dynamic app service plan?')
param isDynamic bool

@description('Unique name for the app service plan')
param uniqueName string

// Useful link on Y1 - https://stackoverflow.com/questions/47522539/server-farm-service-plan-skus
var appServicePlanSkuName = isDynamic ? (isProduction ? 'Y1' : 'Y1') : (isProduction ? 'S1' : 'F1') 

resource creatingAppServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-${baseNameForResources}-${uniqueName}'
  location: location  
  sku: {
    name: appServicePlanSkuName
    tier: isDynamic ? 'Dynamic' : 'Standard'

  }  
  tags: tags  
}

output servicePlanId string = creatingAppServicePlan.id
output servicePlanName string = creatingAppServicePlan.name
