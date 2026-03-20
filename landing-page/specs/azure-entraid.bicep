// Entra ID / Azure AD - Configuration Spec
param tenantId string = subscription().tenantId
param environment string = 'prod'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'identity-services'
}

// App Registration for API
resource appRegistration 'Microsoft.Graph/applications@v1.0' = {
  displayName: 'AI-Services-${environment}'
  description: 'App registration for AI services in ${environment} environment'
  identifierUris: [
    'https://aiservices-${environment}.azureapps.net'
  ]
  packageId: null
  publicClient: {
    redirectUris: []
  }
  requiredResourceAccess: [
    {
      resourceAppId: '00000003-0000-0000-c000-000000000000'  // Microsoft Graph
      resourceAccess: [
        {
          id: 'e1fe6dd8-ba31-4d61-89e7-88639da4683d'  // User.Read
          type: 'Scope'
        }
      ]
    }
  ]
  signInAudience: 'AzureADMultipleOrgs'
  tags: [
    'environment:${environment}'
    'type:ai-service'
  ]
}

// Service Principal
resource servicePrincipal 'Microsoft.Directory/servicePrincipals@v1.0' = {
  appId: appRegistration.appId
  accountEnabled: true
  displayName: appRegistration.displayName
  servicePrincipalType: 'Application'
}

// Application Role for OpenAI Access
resource appRole 'Microsoft.Graph/applications/appRoles@v1.0' = {
  displayName: 'OpenAI.Read'
  value: 'OpenAI.Read'
  id: guid(appRegistration.id, 'openai-read')
  description: 'Read access to OpenAI services'
  isEnabled: true
  allowedMemberTypes: [
    'Application'
  ]
}

output appId string = appRegistration.appId
output servicePrincipalId string = servicePrincipal.id
output tenantId string = tenantId
