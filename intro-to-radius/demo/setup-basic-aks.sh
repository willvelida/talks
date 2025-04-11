# Create the basic AKS Cluster
az aks create --resource-group rg-radius --name wvaksrad --location australiaeast --node-count 3

# Get credentials for your AKS cluster
az aks get-credentials --resource-group rg-radiusdemo --name wvaksrad