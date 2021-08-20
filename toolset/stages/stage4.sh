#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 4: create LustreFS
mv tf_stage3/terraform.tfstate tf_stage4/
terraform -chdir=./tf_stage4 init
terraform -chdir=./tf_stage4 apply
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/lustre-sas.yml
ansible-playbook -i playbooks/inventory ./playbooks/lustre.yml
