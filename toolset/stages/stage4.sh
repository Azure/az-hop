#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 4: create LustreFS
mkdir -p ./tf/stage4
pushd tf/stage4
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
ln -sf ../lustre.tf
ln -sf ../stage2/anf.tf
popd
mv tf/stage3/terraform.tfstate tf/stage4/
terraform -chdir=./tf/stage4 init
terraform -chdir=./tf/stage4 apply
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/lustre-sas.yml
ansible-playbook -i playbooks/inventory ./playbooks/lustre.yml
