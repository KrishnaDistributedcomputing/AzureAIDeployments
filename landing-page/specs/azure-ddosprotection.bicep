// DDoS Protection Plan - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2023-11-01'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'security-services'
}

var ddosProtectionPlanName = 'ddos-${environment}-${uniqueString(resourceGroup().id)}'

resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@${apiVersion}' = {
  name: ddosProtectionPlanName
  location: location
  tags: tags
  properties: {}
}

output ddosProtectionPlanId string = ddosProtectionPlan.id
output ddosProtectionPlanName string = ddosProtectionPlan.name
