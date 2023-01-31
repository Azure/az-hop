#!/bin/bash
rg=$(yq '.resource_group' config.yml)

# If peering, then find out which IP range can be used
peered_vnet=$(yq eval ".network.peering[0].vnet_name" config.yml)
if [ "$peered_vnet" != "null" ]; then
    peered_vnet_rg=$(yq eval ".network.peering[0].vnet_resource_group" config.yml)
    id=$(az network vnet peering list -g $peered_vnet_rg --vnet-name $peered_vnet --query "[?remoteVirtualNetwork.resourceGroup=='$rg'].id" -o tsv)
    az network vnet peering delete --ids $id
fi