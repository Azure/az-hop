#!/bin/bash
EXPECTED_VM_SIZE=${1,,} # convert to lowercase

VM_SIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]')

if [ "$VM_SIZE" != "$EXPECTED_VM_SIZE" ] && [ "$EXPECTED_VM_SIZE" != "any" ]; then
  echo "Wrong VM Size expected. Expected $EXPECTED_VM_SIZE but running on $VM_SIZE"
  echo "ERROR"
  exit 1
fi

echo "Running on $VM_SIZE"
case $AZHPC_VMSIZE in
  standard_nv*)
    nvidia-smi | grep NVIDIA
    if [ $? -eq 1 ]; then 
        echo "ERROR"
        exit 1
    fi
  ;;
esac

sleep 60
echo "PASSED"