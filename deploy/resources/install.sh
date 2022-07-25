#!/bin/bash

echo "* apt updating"
apt update

echo "* Installing the Azure CLI"
while ! which az >/dev/null 2>&1; do
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
done

echo "* Installing jq and git"
apt install -y jq git

echo "* Installing yq"
VERSION=v4.25.3
BINARY=yq_linux_amd64
wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq && chmod +x /usr/bin/yq


echo "* Cloning az-hop repo"
git clone --recursive https://github.com/Azure/az-hop.git -b bicep

cd az-hop
export azhop_root=$(pwd)
cd $azhop_root/deploy

echo "* Logging in to Azure"
az login -i
deployment_name=azureDeploy
resource_group=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | jq -r .compute.resourceGroupName)

echo "* Waiting for deployment to complete"
while deployment_state=$(az deployment group show -g $resource_group -n $deployment_name --query properties.provisioningState -o tsv); [ "$deployment_state" != "Succeeded" ]; do
    echo "Deployment is not yet complete (currently $deployment_state). Waiting..."
    sleep 10
done

echo "* Getting keys from keyvault"
az deployment group show \
    -g $resource_group \
    -n $deployment_name \
    --query properties.outputs \
    | jq 'to_entries | map({(.key): .value.value}) | add' | yq -P | tee outputs.yml

kv="$(yq .keyvault_name outputs.yml)"
adminuser="$(yq .admin_user outputs.yml)"
export admin_pass="$(az keyvault secret show --vault-name $kv -n ${adminuser}-password --query "value" -o tsv)"

echo "* Getting keys from keyvault"
az keyvault secret show --vault-name $kv -n ${adminuser}-pubkey --query "value" -o tsv > ../${adminuser}_id_rsa.pub
az keyvault secret show --vault-name $kv -n ${adminuser}-privkey --query "value" -o tsv > ../${adminuser}_id_rsa
chmod 600 ../${adminuser}_id_rsa*

echo "* Writing build.yml"
cat <<EOF >build.yml
__INSERT_CONFIG_FILE__
EOF

echo "* Generating config files from templates"
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

echo "* Installing dependencies"
cd $azhop_root
./toolset/scripts/install.sh

if [ "$(yq .deploy_sig build.yml)" == "true" ]; then
    echo "* Building images"
    cd $azhop_root/packer
    ./build_image.sh -i azhop-centos79-v2-rdma-gpgpu.json
    ./build_image.sh -i azhop-centos79-desktop3d.json
fi

echo "* Generating passwords"
cd $azhop_root
./create_passwords.sh

echo "* Running Ansible"
./install.sh
