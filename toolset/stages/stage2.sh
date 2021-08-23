#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 2: creating ANF account and dual protocol volume
mkdir -p ./tf/stage2
pushd tf/stage2
ln -sf ../main.tf
ln -sf ../network.tf
ln -sf ../variables.tf
ln -sf ../variables_local.tf
ln -sf ../ad.tf
ln -sf ../jumpbox.tf
ln -sf ../keyvault.tf
popd
mv tf/stage1/terraform.tfstate tf/stage2/
terraform -chdir=./tf/stage2 init
terraform -chdir=./tf/stage2 apply
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/add_users.yml
