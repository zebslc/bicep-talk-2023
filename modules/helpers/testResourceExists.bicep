// NOTE: This is still a work in progress.  The script is not yet complete.

param resourceId string
param userAssignedIdentityName string
param now string = utcNow('F')

resource testResourceExists 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: take(replace('testsExists-${last(split(resourceId,'/'))}', '@', '_'), 64)
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${az.resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentityName)}': {}
    }
  }
  #disable-next-line no-loc-expr-outside-params
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '8.3'
    arguments: ' -resourceId ${resourceId}'
    scriptContent: loadTextContent('../../scripts/testResourceExists.ps1')
    forceUpdateTag: now
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    timeout: 'PT3M'
  }
}

output Exists bool = bool(int(testResourceExists.properties.outputs.Exists))
output ResourceId string = testResourceExists.properties.outputs.ResourceId
