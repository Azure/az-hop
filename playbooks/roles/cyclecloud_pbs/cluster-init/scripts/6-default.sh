#!/bin/bash
# Apply default configuration to the node

# change access to resource so that temp jobs can be written there
chmod 777 /mnt/resource

# Grant domain users sudo with no password
echo "\"%domain users\" ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

# For any NV instances, reinit the session
AZHPC_VMSIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]')
case $AZHPC_VMSIZE in
  standard_nv*)
    init 3
    init 5
  ;;
esac
