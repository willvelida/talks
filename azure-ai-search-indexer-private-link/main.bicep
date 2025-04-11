@description('Random suffix applied to all resources in the template')
param appSuffix string = uniqueString(resourceGroup().id)

@description('The location where all resources in this template should be deployed. Default is the resource group location.')
param location string = resourceGroup().location

@description('The name of the Azure AI Search service that will be deployed.')
@minLength(2)
@maxLength(60)
param aiSearchServiceName string = 'aisearch-${appSuffix}'

@allowed([
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
@description('The SKU of the Azure AI Search service that will be deployed.')
param aiSearchServiceSku string = 'basic'

@description('Replicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier).')
@minValue(1)
@maxValue(12)
param replicaCount int = 1

@description('Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units.')
@allowed([
  1
  2
  3
  4
  6
  12
])
param partitionCount int = 1

@description('The name of the Virtual Network that will be deployed.')
param vnetName string = 'vnet-${appSuffix}'

@description('The name of the subnet that will be deployed')
param subnetName string = 'subnet-${appSuffix}'

@description('The name of the Private Endpoint that will be deployed')
param privateEndpointName string = 'privateEndpoint-${appSuffix}'

@description('The name of the Storage Account that will be deployed')
param storageAccountName string = 'stor${appSuffix}'

@description('The name of the Storage Container that will be deployed')
param containerName string = 'blob'

var vnetAddressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var privateDnsZoneName = 'privatelink.search.windows.net'
var privateDnsZoneGroupName = '${privateEndpointName}/dnsgroupname'

resource aiSearchService 'Microsoft.Search/searchServices@2020-08-01' = {
  name: aiSearchServiceName
  location: location
  sku: {
    name: aiSearchServiceSku
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    publicNetworkAccess: 'disabled'
  }
}

resource aiSearchSharedPrivateLink 'Microsoft.Search/searchServices/sharedPrivateLinkResources@2020-08-01' = {
  name: 'shared'
  parent: aiSearchService
  properties: {
    groupId: 'blob'
    privateLinkResourceId: storageAccount.name
    requestMessage: 'Please approve this request'
  }
  dependsOn: [
    vnet
  ]
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: containerName
  parent: blobServices
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {
    
  }
  dependsOn: [
    vnet
  ]
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: aiSearchService.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}

resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${vnetName}-link'
  parent: privateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  name: privateDnsZoneGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}
