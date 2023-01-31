#!/bin/bash
set -e
set -o pipefail
echo "* apt updating"
apt update

echo "* Installing git"
apt install -y git

echo "* Cloning az-hop repo"
if [ -e az-hop ]; then
    rm -rf az-hop
fi
git clone -b __INSERT_AZHOP_BRANCH__ --recursive https://github.com/Azure/az-hop.git

cd az-hop
export azhop_root=$(pwd)
echo "* Installing azhop toolset dependencies"
./toolset/scripts/install.sh

mkdir -p $azhop_root/deploy
cd $azhop_root/deploy

echo "* Logging in to Azure"
az login -i
deployment_name=azhop
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
    > azhopOutputs.json

kv=$(jq -r .keyvaultName.value azhopOutputs.json)
adminuser=$(jq -r .azhopConfig.value.admin_user azhopOutputs.json)
export admin_pass="$(az keyvault secret show --vault-name $kv -n ${adminuser}-password --query "value" -o tsv)"

echo "* Getting keys from keyvault"
az keyvault secret show --vault-name $kv -n ${adminuser}-pubkey --query "value" -o tsv > ../${adminuser}_id_rsa.pub
az keyvault secret show --vault-name $kv -n ${adminuser}-privkey --query "value" -o tsv > ../${adminuser}_id_rsa
chmod 600 ../${adminuser}_id_rsa*

echo "* Generating config files from templates"
# config.yml
jq .azhopConfig.value azhopOutputs.json | yq -P  > $azhop_root/config.yml

mkdir -p $azhop_root/bin
jq -r .azhopGetSecretScript.value azhopOutputs.json > $azhop_root/bin/get_secret
chmod +x $azhop_root/bin/get_secret
jq -r .azhopConnectScript.value azhopOutputs.json > $azhop_root/bin/connect
chmod +x $azhop_root/bin/connect

mkdir -p $azhop_root/playbooks/group_vars
jq .azhopGlobalConfig.value azhopOutputs.json | yq -P > $azhop_root/playbooks/group_vars/all.yml

jq '.azhopInventory.value.all.hosts *= (.lustre_oss_private_ips.value | to_entries | map({("lustre-oss-" + (.key + 1 | tostring)): {"ansible_host": .value}}) | add // {}) | .azhopInventory.value' azhopOutputs.json | yq -P > $azhop_root/playbooks/inventory

jq .azhopPackerOptions.value azhopOutputs.json > $azhop_root/packer/options.json

if [ "$(jq -r .azhopConfig.value.features.sig azhopOutputs.json)" == "true" ]; then
    echo "* Building images"
    cd $azhop_root/packer
    ./build_image.sh -i azhop-compute-centos-7.9.json
    ./build_image.sh -i azhop-desktop-centos-7.9.json
fi

echo "* Generating passwords"
cd $azhop_root
./create_passwords.sh

echo "* Running Ansible"
#export ANSIBLE_VERBOSITY=2
./install.sh