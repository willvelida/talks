@description('The application suffix applied to all resources')
param appSuffix string = uniqueString(resourceGroup().id)

@description('The location to deploy all Azure resources. Default is location of resource group')
param location string = resourceGroup().location

@description('The name of the App Service Plan that will be provisioned')
param appServicePlanName string = 'asp-${appSuffix}'

@description('The name of the Application Insights resource that will be deployed')
param appInsightsName string = 'ai-${appSuffix}'

@description('The name of the Function App that will be deployed')
param functionAppName string = 'func-${appSuffix}'

@description('The name of the Service Bus that will be deployed')
param serviceBusName string = 'sb-${appSuffix}'

@description('The name of the Storage Account that will be deployed')
param storageAccountName string = 'sa${appSuffix}'

var storageAccountContainerName = 'attachments'
var queueName = 'claimcheck'

@description('The tags that will be applied to all resources')
param tags object = {
  DemoName: 'ClaimCheck'
  DemoSubject: 'Messaging'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    
  }
}

resource function 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  tags: tags
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'SERVICE_BUS_CONNECTION_STRING'
          value: 'Endpoint=sb://${serviceBus.name}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${serviceBus.listKeys().primaryKey}'
        }
        {
          name: 'QUEUE_NAME'
          value: queue.name
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: storageAccountContainerName
  parent: blobServices  
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: queueName
  parent: serviceBus
}
