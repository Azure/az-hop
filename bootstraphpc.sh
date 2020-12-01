#!/bin/bash

echo Welcome to Azure HPC Bootstrap!!

AZ_BIN=$(which az)
TERRAFORM_BIN=$(which terraform)
ANSIBLE_BIN=$(which ansible)
PACKER_BIN=$(which packer)

echo Found az at $AZ_BIN 
echo Found terraform at $TERRAFORM_BIN 
echo Found ansible at $ANSIBLE_BIN 
echo Found packer at $PACKER_BIN 

if [ -e terraform.tfstate ]; then
  echo Terraform state file exists, please remove with:
  echo rm terraform.tfstate*
  echo interrupt with ctrl-C or we continue in 10 seconds...
  sleep 10
fi
./bin/terraform apply -auto-approve -parallelism=30 -var-file configuration.tfvars ./tf/


ansible-playbook -i playbooks/inventory \
  playbooks/ad.yml \
  playbooks/linux.yml \
  playbooks/scheduler.yml \
  playbooks/ccportal.yml \
  playbooks/ood.yml \
  --extra-vars=@playbooks/ood-overrides.yml
