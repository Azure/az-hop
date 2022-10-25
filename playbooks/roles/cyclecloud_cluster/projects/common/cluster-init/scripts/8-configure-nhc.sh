#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../files/azhop-helpers.sh" 
read_os

$SCRIPT_DIR/../files/$os_release/init_nhc.sh

# Install custom checks
cp -v $SCRIPT_DIR/../files/nhc/scripts/* /etc/nhc/scripts/

# Install azhop-node-offline.sh
cp -v $SCRIPT_DIR/../files/nhc/azhop-node-offline.sh /usr/libexec/nhc/
chmod 755 /usr/libexec/nhc/azhop-node-offline.sh

NHC_CONFIG_FILE="/etc/nhc/nhc.conf"
VM_SIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]' | sed 's/standard_//')

NHC_CONFIG_EXTRA="$SCRIPT_DIR/../files/nhc/nhc_${VM_SIZE}.conf"

# Use common config for all compute nodes
if [ -e $NHC_CONFIG_FILE ]; then
    rm -f ${NHC_CONFIG_FILE}.bak
    mv $NHC_CONFIG_FILE ${NHC_CONFIG_FILE}.bak
fi
cp -fv $SCRIPT_DIR/../files/nhc/nhc_common.conf $NHC_CONFIG_FILE

# Append VM size specific config if exists
if [ -e $NHC_CONFIG_EXTRA  ]; then
    cat $NHC_CONFIG_EXTRA >> $NHC_CONFIG_FILE
fi

# Add nvidia-smi health checks for GPU SKUs except NV_v4 as they don't have NVIDIA device
case $VM_SIZE in
    nv*v4)
    ;;
    nc*|nv*|nd*)
        echo " * || check_nvsmi_healthmon" >> $NHC_CONFIG_FILE
    ;;
    # Check HDR InfiniBand on all HBv2 and HBv3 SKUs
    hb*v2|hb*v3)
        echo " * || check_hw_ib 200 mlx5_ib0:1" >> $NHC_CONFIG_FILE
    ;;
    hc44rs)
        echo " * || check_hw_ib 100 mlx5_ib0:1" >> $NHC_CONFIG_FILE
    ;;

esac
