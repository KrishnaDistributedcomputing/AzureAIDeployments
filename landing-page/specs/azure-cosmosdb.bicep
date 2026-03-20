// Azure Cosmos DB - Deployment Spec
param location string = resourceGroup().location
param environment string = 'prod'
param apiVersion string = '2024-05-15'
param tags object = {
  environment: environment
  createdDate: utcNow('u')
  component: 'data-services'
}

var accountName = 'cosmos-${environment}-${uniqueString(resourceGroup().id)}'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@${apiVersion}' = {
  name: accountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: true
      }
    ]
    backupPolicy: {
      type: 'Continuous'
      continuousModeProperties: {
        backupIntervalInMinutes: 60
        backupRetentionIntervalInHours: 8
      }
    }
    networkAclBypass: 'AzureServices'
    publicNetworkAccess: 'Enabled'
  }
}

// Database
resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@${apiVersion}' = {
  parent: cosmosAccount
  name: 'app-database'
  properties: {
    resource: {
      id: 'app-database'
    }
  }
}

// Container
resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@${apiVersion}' = {
  parent: database
  name: 'documents'
  properties: {
    resource: {
      id: 'documents'
      partitionKey: {
        paths: ['/userId']
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
      }
    }
    options: {
      throughput: 1000
    }
  }
}

output cosmosDbId string = cosmosAccount.id
output cosmosDbEndpoint string = cosmosAccount.properties.documentEndpoint
output cosmosDbName string = cosmosAccount.name
output databaseName string = database.name
