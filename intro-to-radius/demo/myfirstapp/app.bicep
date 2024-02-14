import radius as radius
param application string
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

resource redis 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'redis'
  properties: {
    environment: environment
    application: application
    recipe: {
      name: 'azure'
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
