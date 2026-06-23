targetScope = 'resourceGroup'

@description('Recovery Services vault name.')
param recoveryServicesVaultName string

@description('Backup vault name.')
param backupVaultName string

@description('Whether the Backup vault was deployed.')
param deployBackupVault bool = true

@description('Optional principal ID assigned Backup Contributor.')
param backupAdminPrincipalId string = ''

@description('Optional principal ID assigned Backup Operator.')
param restoreOperatorPrincipalId string = ''

@description('Optional principal ID assigned Backup Reader.')
param securityReviewerPrincipalId string = ''

var backupContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e467623-bb1f-42f4-a55d-6e525e11384b')
var backupOperatorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00c29273-979b-4161-815c-10b084fb9324')
var backupReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a795c7a0-d4a2-40c1-ae25-d81f01202912')

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2024-10-01' existing = {
  name: recoveryServicesVaultName
}

resource backupVault 'Microsoft.DataProtection/backupVaults@2024-04-01' existing = if (deployBackupVault) {
  name: backupVaultName
}

resource backupAdminRsv 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(backupAdminPrincipalId)) {
  scope: recoveryServicesVault
  name: guid(recoveryServicesVault.id, backupAdminPrincipalId, 'backup-contributor')
  properties: {
    principalId: backupAdminPrincipalId
    roleDefinitionId: backupContributorRoleDefinitionId
    principalType: 'Group'
  }
}

resource restoreOperatorRsv 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(restoreOperatorPrincipalId)) {
  scope: recoveryServicesVault
  name: guid(recoveryServicesVault.id, restoreOperatorPrincipalId, 'backup-operator')
  properties: {
    principalId: restoreOperatorPrincipalId
    roleDefinitionId: backupOperatorRoleDefinitionId
    principalType: 'Group'
  }
}

resource securityReviewerRsv 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(securityReviewerPrincipalId)) {
  scope: recoveryServicesVault
  name: guid(recoveryServicesVault.id, securityReviewerPrincipalId, 'backup-reader')
  properties: {
    principalId: securityReviewerPrincipalId
    roleDefinitionId: backupReaderRoleDefinitionId
    principalType: 'Group'
  }
}

resource backupAdminBackupVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployBackupVault && !empty(backupAdminPrincipalId)) {
  scope: backupVault
  name: guid(backupVault.id, backupAdminPrincipalId, 'backup-vault-contributor')
  properties: {
    principalId: backupAdminPrincipalId
    roleDefinitionId: backupContributorRoleDefinitionId
    principalType: 'Group'
  }
}

resource restoreOperatorBackupVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployBackupVault && !empty(restoreOperatorPrincipalId)) {
  scope: backupVault
  name: guid(backupVault.id, restoreOperatorPrincipalId, 'backup-vault-operator')
  properties: {
    principalId: restoreOperatorPrincipalId
    roleDefinitionId: backupOperatorRoleDefinitionId
    principalType: 'Group'
  }
}
