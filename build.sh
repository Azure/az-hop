#!/bin/bash

UUID="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
RESOURCE_GROUP="hpc_$UUID"
echo $RESOURCE_GROUP > resource_group.txt
terraform init ./tf
terraform apply -auto-approve -parallelism=30 -var location=westeurope -var resource_group=$RESOURCE_GROUP ./tf

