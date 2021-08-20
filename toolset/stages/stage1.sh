#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 1: creating jumpbox and AD node and keyvault
mv tf_stage0/terraform.tfstate tf_stage1/
terraform -chdir=./tf_stage1 init
terraform -chdir=./tf_stage1 apply
ansible-playbook -i playbooks/inventory ./playbooks/ad.yml
./create_passwords.sh
