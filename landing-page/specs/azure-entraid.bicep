// Microsoft Entra ID (DS-ENTRAID-001) - Identity and Access Baseline
// Note: This specification assumes Microsoft Graph/Bicep support is available in the deployment environment.

targetScope = 'tenant'

param location string = 'eastus'
param environment string = 'prod'
param appDisplayName string = 'ai-platform-core'
param groupPrefix string = 'ai-platform'
param graphApiVersion string = 'v1.0'
param requireMfaForAdmins bool = true
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'identity-services'
  spec: 'DS-ENTRAID-001'
}

var appName = '${appDisplayName}-${environment}'
var operatorsGroupName = '${groupPrefix}-${environment}-operators'
var auditorsGroupName = '${groupPrefix}-${environment}-auditors'

// Application registration used by platform automation and APIs.
resource appRegistration 'Microsoft.Graph/applications@${graphApiVersion}' = {
  displayName: appName
  description: 'Entra application for AI platform workloads in ${environment}'
  signInAudience: 'AzureADMyOrg'
  identifierUris: [
    'api://${appName}'
  ]
  requiredResourceAccess: [
    {
      resourceAppId: '00000003-0000-0000-c000-000000000000'
      resourceAccess: [
        {
          id: 'e1fe6dd8-ba31-4d61-89e7-88639da4683d'
          type: 'Scope'
        }
      ]
    }
  ]
  tags: [
    'environment:${environment}'
    'spec:DS-ENTRAID-001'
  ]
}

// Enterprise app (service principal) representation of the application.
resource servicePrincipal 'Microsoft.Graph/servicePrincipals@${graphApiVersion}' = {
  appId: appRegistration.appId
  accountEnabled: true
}

// Role groups that can be mapped into RBAC or app role assignments.
resource operatorsGroup 'Microsoft.Graph/groups@${graphApiVersion}' = {
  displayName: operatorsGroupName
  description: 'Operations group for ${environment} platform activities'
  mailEnabled: false
  mailNickname: replace(operatorsGroupName, '-', '')
  securityEnabled: true
}

resource auditorsGroup 'Microsoft.Graph/groups@${graphApiVersion}' = {
  displayName: auditorsGroupName
  description: 'Audit group for ${environment} platform activities'
  mailEnabled: false
  mailNickname: replace(auditorsGroupName, '-', '')
  securityEnabled: true
}

// Informational outputs for downstream automation.
output tenantId string = tenant().tenantId
output location string = location
output appObjectId string = appRegistration.id
output appId string = appRegistration.appId
output servicePrincipalObjectId string = servicePrincipal.id
output operatorsGroupId string = operatorsGroup.id
output auditorsGroupId string = auditorsGroup.id
output privilegedMfaRequired bool = requireMfaForAdmins
output tags object = tags