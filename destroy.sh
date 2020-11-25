#!/bin/bash

RESOURCE_GROUP=$(cat resource_group.txt)
terraform init ./tf
terraform destroy -auto-approve -parallelism=30 -var location=westeurope -var resource_group=$RESOURCE_GROUP ./tf
