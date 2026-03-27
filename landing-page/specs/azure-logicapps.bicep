// Azure Logic Apps - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2019-05-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'workflow-automation'
}

var workflowName = 'la-${environment}-${uniqueString(resourceGroup().id)}'

resource logicApp 'Microsoft.Logic/workflows@${apiVersion}' = {
  name: workflowName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    parameters: {}
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {}
          }
        }
      }
      actions: {
        response: {
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
            body: {
              message: 'Logic App workflow executed'
              environment: environment
            }
          }
          runAfter: {}
        }
      }
      outputs: {}
    }
  }
}

output workflowId string = logicApp.id
output workflowName string = logicApp.name
output principalId string = logicApp.identity.principalId
