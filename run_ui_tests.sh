#!/bin/bash
AZHOP_CONFIG=config.yml
ANSIBLE_VARIABLES=playbooks/group_vars/all.yml

echo "Retrieve Username, password and FQDN"
key_vault=$(yq eval '.key_vault' $ANSIBLE_VARIABLES)
user=$(yq eval '.users[0].name' $AZHOP_CONFIG)
password=$(./bin/get_secret $user)
export AZHOP_USER=$user
export AZHOP_PASSWORD=$password

fqdn=$(yq eval '.ondemand_fqdn' $ANSIBLE_VARIABLES)
export AZHOP_FQDN="https://$fqdn"

echo "FQDN is $AZHOP_FQDN"
echo "User is $AZHOP_USER"
npx playwright test --config=tests/playwright.config.ts $@
