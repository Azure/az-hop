#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 0: creating ResourceGroup, StorageAccount and VNet
mkdir -p ./tf/stage0
pushd tf/stage0
ln -sf ../main.tf
ln -sf ../network.tf
ln -sf ../variables.tf
ln -sf ../variables_local.tf
popd
terraform -chdir=./tf/stage0 init
terraform -chdir=./tf/stage0 apply
