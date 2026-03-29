RESOURCE_GROUP="hybrid-scale-rg"
VMSS_NAME="az-vmss-create"

# Apply (or update) the custom script extension
az vmss extension set \
  --resource-group $RESOURCE_GROUP \
  --vmss-name $VMSS_NAME \
  --name CustomScript \
  --publisher Microsoft.Azure.Extensions \
  --version 2.1 \
  --protected-settings '{
    "script": "'"$(base64 -w 0 vmss-setup.sh)"'"
  }'