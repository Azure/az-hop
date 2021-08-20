#!/bin/bash

export TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"

echo Stage 0: creating ResourceGroup, StorageAccount and VNet
terraform -chdir=./tf_stage0 init
terraform -chdir=./tf_stage0 apply
