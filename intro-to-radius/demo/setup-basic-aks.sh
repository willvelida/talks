# Create the basic AKS Cluster
az aks create --subscription <subscription-id> --resource-group <resource-group-name> --name <aks-cluster-name> --location <azure-region> --node-count 1

# Get credentials for your AKS cluster
az aks get-credentials --subscription <subscription-id> --resource-group <resource-group-name> --name <aks-cluster-name>