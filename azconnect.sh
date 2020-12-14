#!/bin/bash

export ARM_CLIENT_ID="fd1d1fea-cf55-483b-9e2d-36e8491abeca" 
export ARM_CLIENT_SECRET="1564e592-d807-3454-cfa3-19df1cde0dba" 
export ARM_TENANT_ID=72f988bf-86f1-41af-91ab-2d7cd011db47
export ARM_SUBSCRIPTION_ID=f5a67d06-2d09-4090-91cc-e3298907a021

az login --service-principal -u $ARM_CLIENT_ID -p "$ARM_CLIENT_SECRET" --tenant $ARM_TENANT_ID
az account set -s $ARM_SUBSCRIPTION_ID
