#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 1: creating jumpbox and AD node and keyvault
mkdir -p ./tf/stage1
pushd tf/stage1
ln -sf ../main.tf
ln -sf ../network.tf
ln -sf ../variables.tf
ln -sf ../variables_local.tf
ln -sf ../ad.tf
ln -sf ../jumpbox.tf
ln -sf ../keyvault.tf
popd
mv ./tf/stage0/terraform.tfstate ./tf/stage1/
terraform -chdir=./tf/stage1 init
terraform -chdir=./tf/stage1 apply
ansible-playbook -i playbooks/inventory ./playbooks/ad.yml
./create_passwords.sh
