#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 6: creating Windows viz node
mkdir -p ./tf/stage6/templates
pushd tf/stage6
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
pushd tf/stage6/templates
ln -sf ../../templates/connect.tmpl
ln -sf ../../templates/get_secret.tmpl
ln -sf ../../templates/global_variables.tmpl
# ln -sf ../../templates/inventory.tmpl
popd
mv tf/stage5/terraform.tfstate tf/stage6/
terraform -chdir=./tf/stage6 init || exit 1
terraform -chdir=./tf/stage6 apply || exit 1
