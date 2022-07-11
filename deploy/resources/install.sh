#!/bin/bash

apt update

while ! which az >/dev/null 2>&1; do
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
done

apt install -y jq git
snap install yq

git clone --recursive https://github.com/Azure/az-hop.git -b bicep

cd az-hop
export azhop_root=$(pwd)
cd $azhop_root/deploy

az login -i
deployment_name=azureDeploy
resource_group=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | jq -r .compute.resourceGroupName)

while deployment_state=$(az deployment group show -g $resource_group -n $deployment_name --query properties.provisioningState -o tsv); [ "$deployment_state" != "Succeeded" ]; do
    echo "Deployment is not yet complete (currently $deployment_state). Waiting..."
    sleep 10
done

az deployment group show \
    -g $resource_group \
    -n $deployment_name \
    --query properties.outputs \
    | jq 'to_entries | map({(.key): .value.value}) | add' | yq -P | tee outputs.yml

kv="$(yq .keyvault_name <outputs.yml)"
adminuser="$(yq .admin_user <outputs.yml)"
export admin_pass="$(az keyvault secret show --vault-name $kv -n ${adminuser}-password --query "value" -o tsv)"

az keyvault secret show --vault-name $kv -n ${adminuser}-pubkey --query "value" -o tsv > ../${adminuser}_id_rsa.pub
az keyvault secret show --vault-name $kv -n ${adminuser}-privkey --query "value" -o tsv > ../${adminuser}_id_rsa
chmod 600 ../${adminuser}_id_rsa*

cat <<EOF >build.yml
__INSERT_CONFIG_FILE__
EOF


./resources/generate_template_file.py -i resources/azhop-config-templates/config.yml.j2 -o $azhop_root/config.yml

mkdir -p $azhop_root/bin
./resources/generate_template_file.py -i resources/azhop-config-templates/get_secret.j2 -o $azhop_root/bin/get_secret
chmod +x $azhop_root/bin/get_secret
./resources/generate_template_file.py -i resources/azhop-config-templates/connect.j2 -o $azhop_root/bin/connect
chmod +x $azhop_root/bin/connect

mkdir -p $azhop_root/playbooks/group_vars
./resources/generate_template_file.py -i resources/azhop-config-templates/global_variables.j2 -o $azhop_root/playbooks/group_vars/all.yml

./resources/generate_template_file.py -i resources/azhop-config-templates/inventory.j2 -o $azhop_root/playbooks/inventory

./resources/generate_template_file.py -i resources/azhop-config-templates/options.json.j2 -o $azhop_root/packer/options.json


cd $azhop_root
./toolset/scripts/install.sh

cd $azhop_root/packer
./build_image.sh -i azhop-centos79-v2-rdma-gpgpu.json
./build_image.sh -i centos-7.8-desktop-3d.json

cd $azhop_root
./create_passwords.sh

./install.sh
