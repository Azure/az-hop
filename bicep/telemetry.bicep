targetScope = 'resourceGroup'

resource telemetry 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'pid-58d16d1a-5b7c-11ed-8042-00155d5d7a47'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
      outputs: {
        telemetry: {
          type: 'String'
          value: 'For more information, see https://azure.github.io/az-hop/deploy/telemetry.html'
        }
      }
    }
  }
}
