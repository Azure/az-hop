#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 5: creating ondemand
mv tf_stage4/terraform.tfstate tf_stage5/
terraform -chdir=./tf_stage5 init || exit 1
terraform -chdir=./tf_stage5 apply || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/ood.yml --extra-vars=@playbooks/ood-overrides.yml || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/grafana.yml || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/telegraf.yml || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/chrony.yml || exit 1
