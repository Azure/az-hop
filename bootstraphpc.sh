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

rm terraform.tfstate

./bin/terraform apply -var-file configuration.tfvars ./tf/

ansible-playbook -i playbooks/inventory playbooks/ad.yml playbooks/linux.yaml playbooks/scheduler.yml playbooks/ccportal.yml
