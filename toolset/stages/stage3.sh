#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 3: creating ccportal, scheduler and sig
mv tf_stage2/terraform.tfstate tf_stage3/
terraform -chdir=./tf_stage3 init
terraform -chdir=./tf_stage3 apply
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/ccportal.yml
ansible-playbook -i playbooks/inventory ./playbooks/ccpbs.yml
ansible-playbook -i playbooks/inventory ./playbooks/scheduler.yml
