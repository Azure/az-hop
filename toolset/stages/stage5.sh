#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 5: creating ondemand
mkdir -p ./tf/stage5
pushd tf/stage5
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
ln -sf ../ondemand.tf
ln -sf ../grafana.tf
ln -sf ../stage2/anf.tf
popd
mv tf/stage4/terraform.tfstate tf/stage5/
terraform -chdir=./tf/stage5 init || exit 1
terraform -chdir=./tf/stage5 apply || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/ood.yml --extra-vars=@playbooks/ood-overrides.yml || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/grafana.yml || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/telegraf.yml || exit 1
ansible-playbook -i playbooks/inventory ./playbooks/chrony.yml || exit 1
