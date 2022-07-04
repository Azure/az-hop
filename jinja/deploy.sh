#!/bin/bash

apt update

while ! which az >/dev/null 2>&1; do
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
done

apt install -y jq git
snap install yq

git clone --recursive https://github.com/Azure/az-hop.git -b private_jumpbox

cd az-hop
export azhop_root=$(pwd)
cd jinja

az login -i
deployment_name=azhop
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

az keyvault secret show --vault-name $kv -n ${adminuser}-pubkey --query "value" -o tsv > ${adminuser}_id_rsa.pub
az keyvault secret show --vault-name $kv -n ${adminuser}-privkey --query "value" -o tsv > ${adminuser}_id_rsa
chmod 600 ${adminuser}_id_rsa*

cat <<EOF >config.yml
__INSERT_CONFIG_FILE__
EOF
./generate_template_file.py

cp templates/config.yml ../config.yml
mkdir -p ../bin
cp templates/get_secret ../bin
chmod +x ../bin/get_secret
cp templates/connect ../bin
chmod +x ../bin/connect
mkdir -p ../playbooks/group_vars
cp templates/global_variables ../playbooks/group_vars/all.yml
# need to add admin password for AD (or just remove from config...)
cp templates/inventory ../playbooks
cp templates/options.json ../packer

cd ..
./toolset/scripts/install.sh

cd packer
./build_image.sh -i azhop-centos79-v2-rdma-gpgpu.json
./build_image.sh -i centos-7.8-desktop-3d.json

cd ..
./create_passwords.sh

./install.sh
