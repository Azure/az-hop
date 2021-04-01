#!/bin/bash
EXPECTED_VM_SIZE=${1,,}

VM_SIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]')

if [ "$VM_SIZE" != "$EXPECTED_VM_SIZE" ]; then
  echo "Wrong VM Size expected. Expected $EXPECTED_VM_SIZE but running on $VM_SIZE"
  exit 1
fi

sleep 60
