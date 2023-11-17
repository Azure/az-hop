#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install NHC if not already installed in the image
if [ ! -f /usr/sbin/nhc ] || [ ! -d /opt/azurehpc/test/azurehpc-health-checks ] ; then
    mkdir -p /opt/azurehpc/test/
    cd /opt/azurehpc/test/
    git clone https://github.com/Azure/azurehpc-health-checks.git
    cd azurehpc-health-checks
    ./install-nhc.sh
fi

# Install azhop-node-offline.sh
cp -v $SCRIPT_DIR/../files/nhc/azhop-node-offline.sh /usr/libexec/nhc/
chmod 755 /usr/libexec/nhc/azhop-node-offline.sh

# Use our own NHC config files
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