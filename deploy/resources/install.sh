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
git clone --recursive https://github.com/Azure/az-hop.git

cd az-hop
export azhop_root=$(pwd)
echo "* Installing azhop toolset dependencies"
./toolset/scripts/install.sh

mkdir -p $azhop_root/deploy
cd $azhop_root/deploy

echo "* Logging in to Azure"
az login -i
deployment_name="pid-58d16d1a-5b7c-11ed-8042-00155d5d7a47"
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

# Checkout the branch
branch="$(yq .branch_name outputs.yml)"
if [ "$branch" != "main" ]; then
    echo "Checkout branch $branch"
    pushd $azhop_root
    git checkout $branch
    popd
fi

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

if [ "$(yq .deploy_sig deploy/build.yml)" == "true" ]; then
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
