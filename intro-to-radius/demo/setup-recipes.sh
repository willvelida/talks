# initialize new environment
rad init

# view the Recipes in your environment
rad recipe list

# deploy application
rad deploy ./app.bicep

# list Kubernetes Pods
kubectl get pods -n default-recipes

# port forward the container to your machine
rad resource expose containers frontend --port 3000

# delete Redis cache
rad resource delete rediscaches db

# update rad environment
rad env update myEnvironment --azure-subscription-id myAzureSubscriptionId --azure-resource-group  myAzureResourceGroup

# run az ad sp create-for-rbac
az ad sp create-for-rbac

# add Azure service principal to your Radius installation
rad credential register azure --client-id myClientId  --client-secret myClientSecret  --tenant-id myTenantId

# register recipe to your Radius environment
rad recipe register azure --environment default --template-kind bicep --template-path ghcr.io/radius-project/recipes/azure/rediscaches:latest --resource-type Applications.Datastores/redisCaches

# redeploy app to your environment
rad deploy ./app.bicep