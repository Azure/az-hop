#!/bin/bash
set -eo pipefail

read_os()
{
    os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | xargs)
    os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | xargs)
    full_version=$(cat /etc/os-release | grep "^VERSION\=" | cut -d'=' -f 2 | xargs)
}

retry_command() {
    local cmd=$1
    local retries=${2:-5}
    local delay=${3:-10}

    set +eo pipefail

    for ((i=0; i<retries; i++)); do
        echo "Running command: $cmd"
        $cmd

        if [ $? -eq 0 ]; then
            echo "Command succeeded!"
            set -eo pipefail
            return 0
        else
            echo "Command failed. Retrying in ${delay}s..."
            sleep $delay
        fi
    done

    echo "Command failed after $retries retries."
    set -eo pipefail
    return 1
}
read_os

# echo "* apt updating"
# retry_command "apt update"

echo "* Update SSH port"
sed -i 's/^#Port 22/Port __SSH_PORT__/' /etc/ssh/sshd_config
systemctl restart sshd

case $os_release in
    centos|rhel|almalinux)
        echo "* Installing git"
        retry_command "yum install -y git"
        ;;
    ubuntu)
        echo "* Installing git"
        retry_command "apt install -y git"
        ;;
    *)
        echo "Unsupported OS"
        ;;
esac


echo "* Cloning az-hop repo"
cd /opt
if [ -e az-hop ]; then
    rm -rf az-hop
fi
git clone -b __INSERT_AZHOP_BRANCH__ --recursive https://github.com/Azure/az-hop.git

cd az-hop
export azhop_root=$(pwd)
echo "* Installing azhop toolset dependencies"
export HOME=/root # hack to fix conda install in cloud-init
retry_command "./toolset/scripts/install.sh"

mkdir -p $azhop_root/deploy
cd $azhop_root/deploy

echo "* Logging in to Azure"
mds=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01")
cloudenv=$(echo $mds | jq -r '.compute.azEnvironment' | tr '[:upper:]' '[:lower:]')
if [ "$cloudenv" == "azureusgovernmentcloud" ]; then
    echo "Running in Azure US Government Cloud"
    az cloud set --name AzureUSGovernment
fi
# Add retry logic as it could take some delay to apply the Managed Identity
timeout 120s bash -c 'until az login -i; do sleep 10; done'

deployment_name=azhop
resource_group=$(echo $mds | jq -r '.compute.resourceGroupName')

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
chmod 600 ../${adminuser}_id_rsa
chmod 644 ../${adminuser}_id_rsa.pub

echo "* Generating config files from templates"
# config.yml
jq .azhopConfig.value azhopOutputs.json | yq -P  > $azhop_root/config.yml

mkdir -p $azhop_root/bin
jq -r .azhopGetSecretScript.value azhopOutputs.json > $azhop_root/bin/get_secret
chmod +x $azhop_root/bin/get_secret
jq -r .azhopConnectScript.value azhopOutputs.json > $azhop_root/bin/connect
chmod +x $azhop_root/bin/connect

# create the group_vars/all.yml
mkdir -p $azhop_root/playbooks/group_vars
jq '. | .azhopGlobalConfig.value.global_config_file=$param' --arg param $azhop_root/config.yml azhopOutputs.json > tmp.json
cp tmp.json azhopOutputs.json
jq .azhopGlobalConfig.value azhopOutputs.json | yq -P > $azhop_root/playbooks/group_vars/all.yml

jq '.azhopInventory.value' azhopOutputs.json | yq -P > $azhop_root/playbooks/inventory
# substitute passwords into the file
#  - __ADMIN_PASSWORD__
sed -i "s/__ADMIN_PASSWORD__/$(sed 's/[&/\]/\\&/g' <<< $admin_pass)/g" $azhop_root/playbooks/inventory

jq .azhopPackerOptions.value azhopOutputs.json > $azhop_root/packer/options.json

echo "* Generating passwords"
cd $azhop_root
./create_passwords.sh

echo "* Running Ansible"
#export ANSIBLE_VERBOSITY=2
retry_command "./install.sh"