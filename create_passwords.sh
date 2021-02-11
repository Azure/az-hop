#!/bin/bash
# This script will create a random password per user and store it in the keyvault under a secret named <user>-password

AZHOP_CONFIG=config.yml
ANSIBLE_VARIABLES=playbooks/group_vars/all.yml

if [ ! -e $AZHOP_CONFIG ]; then
  echo "$AZHOP_CONFIG doesn't exist, exiting"
  exit 1
fi

key_vault=$(yq eval '.key_vault' $ANSIBLE_VARIABLES)
if [ "$key_vault" == "" ]; then
  echo "Keyvault retrieved from $ANSIBLE_VARIABLES is empty"
  exit 1
fi

users=$(yq eval '.users[].name' $AZHOP_CONFIG)
for user in $users; do
  current_password=$(az keyvault secret list --vault-name $key_vault --query "[?name=='$user-password'].name" -o tsv)
  if [ "$current_password" == "" ]; then
    password=$(openssl rand -base64 20)
    az keyvault secret set --value $password --name $user-password --vault-name $key_vault -o table > /dev/null
    echo "Generating a password for $user and storing it as secret $user-password in keyvault $key_vault"
  else
    echo "User $user has already a password stored in keyvault $key_vault"
  fi
done
