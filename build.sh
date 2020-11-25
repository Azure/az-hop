#!/bin/bash
RG_FILE=resource_group.txt

if [ ! -e $RG_FILE ]; then
  UUID="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
  RESOURCE_GROUP="hpc_$UUID"
  echo $RESOURCE_GROUP > $RG_FILE
else
  RESOURCE_GROUP=$(cat $RG_FILE)
fi

terraform init ./tf
terraform apply -auto-approve -parallelism=30 -var location=westeurope -var resource_group=$RESOURCE_GROUP ./tf

