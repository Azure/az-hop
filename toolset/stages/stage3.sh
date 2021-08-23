#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 3: creating ccportal, scheduler and sig
mkdir -p ./tf/stage3
pushd tf/stage3
ln -sf ../main.tf
ln -sf ../network.tf
ln -sf ../variables.tf
ln -sf ../variables_local.tf
ln -sf ../ad.tf
ln -sf ../jumpbox.tf
ln -sf ../keyvault.tf
ln -sf ../sig.tf
ln -sf ../ccportal.tf
ln -sf ../scheduler.tf
ln -sf ../stage2/anf.tf
popd
mv tf/stage2/terraform.tfstate tf/stage3/
terraform -chdir=./tf/stage3 init
terraform -chdir=./tf/stage3 apply
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/ccportal.yml
ansible-playbook -i playbooks/inventory ./playbooks/ccpbs.yml
ansible-playbook -i playbooks/inventory ./playbooks/scheduler.yml
