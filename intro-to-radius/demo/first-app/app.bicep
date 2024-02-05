import radius as radius

@description('The ID of your Radius Application. Set automatically by the rad CLI')
param application string

@description('The ID of your Radius environment. Set automatically by the rad CLI')
param environment string

resource demo 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo'
  properties: {
    application: application
    container: {
      image: 'ghcr.io/radius-project/tutorial/webapp:edge'
      ports: {
        web: {
          containerPort: 3000
        }
      }
    }
    connections: {
      mongodb: {
        source: mongodb.id
      }
      backend: {
        source: 'http://backend:80'
      }
    }
  }
}

resource mongodb 'Applications.Datastores/mongoDatabases@2023-10-01-preview' = {
  name: 'mongodb'
  properties: {
    environment: environment
    application: application
  }
}

resource backend 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'backend'
  properties: {
    application: application
    container: {
      image: 'nginx:latest'
      ports: {
        api: {
          containerPort: 80
        }
      }
    }
  }
}

resource gateway 'Applications.Core/gateways@2023-10-01-preview' = {
  name: 'gateway'
  properties: {
    application: application
    routes: [
      {
        path: '/'
        destination: 'http://demo:3000'
      }
    ]
  }
}
