import radius as radius

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

@description('The ID of your Radius Environment. Automatically injected by the rad CLI.')
param environment string

resource demo 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo'
  properties: {
    application: application
    container: {
      image: 'ghcr.io/radius-project/samples/demo:latest'
      ports: {
        web: {
          containerPort: 3000
        }
      }
    }
    connections: {
      redis: {
        source: cache.id
      }
    }
  }
}

resource cache 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'cache'
  properties: {
    environment: environment
    application: application 
  }
}
