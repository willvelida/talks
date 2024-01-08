@description('Random suffix for resource names')
param applicationName string = uniqueString(resourceGroup().id)

@description('The location for all resources in the template. Default is the location of the resource group')
param location string = resourceGroup().location

@description('The name of the container app environment')
param containerAppEnvName string = 'env${applicationName}'

@description('The name of the Log Analytics workspace that will be deployed.')
param logAnalyticsWorkspaceName string = 'law${applicationName}'

@description('The name of the Application Insights instance that will be deployed.')
param applicationInsightsName string = 'ai${applicationName}'

@description('The name of the Azure Container Registry that will be deployed.')
param containerRegistryName string = 'acr${applicationName}'

@description('The name of the Service Bus Namespace that will be deployed')
param serviceBusNamespaceName string = 'sb${applicationName}'

@description('The name of the Storage Account that will be deployed')
param storageAccountName string = 'sa${applicationName}'

var queueName = 'outqueue'
var enqueueMessage = 'enqueuemessage'
var receiveMessage = 'receviemessage'
var blobChecker = 'blockchecker'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource outQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: queueName
  parent: serviceBus
  properties: {
    defaultMessageTimeToLive: 'P14D'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource dataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/data'
}

resource env 'Microsoft.App/managedEnvironments@2023-08-01-preview' = {
  name: containerAppEnvName
  location: location
  properties: {
    daprAIConnectionString: appInsights.properties.ConnectionString
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource storageDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-08-01-preview' = {
  name: 'storagecomponent'
  parent: env
  properties: {
    componentType: 'state.azure.blobstorage'
    version: 'v1'
    metadata: [
      {
        name: 'accountName'
        value: storageAccount.name
      }
      {
        name: 'accountKey'
        value: listKeys(storageAccount.id, '2023-01-01').keys[0].value
      }
      {
        name: 'containerName'
        value: dataContainer.name
      }
    ]
    scopes: [
      receiveMessageApp.name
      blobCheckerApp.name
    ]
  }
}

resource queueDaprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-08-01-preview' = {
  name: 'queuecomponent'
  parent: env
  properties: {
    componentType: 'pubsub.azure.servicebus.queues'
    version: 'v1'
    metadata: [
      {
        name: 'connectionString'
        value: listKeys(resourceId('Microsoft.ServiceBus/namespaces/AuthorizationRules', serviceBus.name, 'RootManageSharedAccessKey'), '2015-08-01').primaryConnectionString
      }
    ]
    scopes: [
      enqueueMessageApp.name
      receiveMessageApp.name
    ]
  }
}

resource enqueueMessageApp 'Microsoft.App/containerApps@2023-08-01-preview' = {
  name: enqueueMessage
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        targetPort: 80
        external: true
      }
      dapr: {
        enabled: true
        appId: enqueueMessage
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: enqueueMessage
        }
      ]
    }
  }
}

resource receiveMessageApp 'Microsoft.App/containerApps@2023-08-01-preview' = {
  name: receiveMessage
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        targetPort: 80
        external: true
      }
      dapr: {
        enabled: true
        appId: receiveMessage
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: receiveMessage
        }
      ]
    }
  }
}

resource blobCheckerApp 'Microsoft.App/containerApps@2023-08-01-preview' = {
  name: blobChecker
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        targetPort: 80
        external: true
      }
      dapr: {
        enabled: true
        appId: blobChecker
        appProtocol: 'http'
        appPort: 80
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: blobChecker
        }
      ]
    }
  }
}
