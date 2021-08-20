#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 2: creating ANF account and dual protocol volume
mv tf_stage1/terraform.tfstate tf_stage2/
terraform -chdir=./tf_stage2 init
terraform -chdir=./tf_stage2 apply
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/add_users.yml
