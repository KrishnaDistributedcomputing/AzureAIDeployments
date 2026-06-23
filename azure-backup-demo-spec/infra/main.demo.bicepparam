using './main.bicep'

param adminPassword = readEnvironmentVariable('AZURE_BACKUP_DEMO_ADMIN_PASSWORD', 'Replace-With-A-Strong-Password-123!')
param location = 'canadacentral'
param environmentName = 'backup-demo'
param regionCode = 'cc'
param owner = 'krishna'
param autoDeleteAfter = 'review-before-delete'
param adminUsername = 'azureadmin'
param deployWindowsVm = true
param deployLinuxVm = false
param deployAzureFiles = true
param deployBackupVault = true
param deployDiskBackup = false
param enableSoftDelete = true
param enableImmutableVault = false
param retentionDays = 7
param storageRedundancy = 'LRS'
param alertEmail = ''
param backupAdminPrincipalId = ''
param restoreOperatorPrincipalId = ''
param securityReviewerPrincipalId = ''
