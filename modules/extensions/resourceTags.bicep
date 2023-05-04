// Configuration information
// https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/tags?pivots=deployment-language-bicep

@description('What additional tag do you want to add to the resource?')
param tagToAdd string

@description('What tag do you want to set the tag to?')
param tagValue string

var tags = resourceGroup().tags
var newTags = {
  '${tagToAdd}': tagValue
}
var tagExists = contains(tags, tagToAdd)
var totalTags = union(tags, newTags)

// Set a custom tag on the resource - usually done to show we have added something that can only be done once
resource resourceTags 'Microsoft.Resources/tags@2021-04-01' = if (!tagExists) {
  name: 'default'
  scope: resourceGroup()
  properties: {
    tags: totalTags
  } 
}
output tagExists bool = tagExists
output existingTags object = tags
