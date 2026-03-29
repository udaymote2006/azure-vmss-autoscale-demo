#!/bin/bash
export AZURE_CONFIG_DIR=~/.azure
az login --service-principal -u $(jq -r .clientId ~/.azure/hybrid-sp.json) \
  -p $(jq -r .clientSecret ~/.azure/hybrid-sp.json) \
  --tenant $(jq -r .tenantId ~/.azure/hybrid-sp.json) > /dev/null
# Assumes you are already logged in with az login or service principal
RESOURCE_GROUP="hybrid-scale-rg"
VMSS_NAME="az-vmss-create"

echo "$(date) - Scaling out VMSS by 1 instance..."
az vmss scale --resource-group $RESOURCE_GROUP --name $VMSS_NAME --new-capacity $(($(az vmss show --resource-group $RESOURCE_GROUP --name $VMSS_NAME --query 'capacity' -o tsv)+1))

# Optional: Update custom script extension to ensure app is deployed
echo "$(date) - App deployment triggered on new instances (via VMSS custom script extension)."