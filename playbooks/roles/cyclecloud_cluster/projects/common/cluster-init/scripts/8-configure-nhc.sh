#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
JETPACK=/opt/cycle/jetpack/bin/jetpack

# Don't configure NHC if not enabled
enabled_nhc=$($JETPACK config healthchecks.enabled | tr '[:upper:]' '[:lower:]')
if [[ $enabled_nhc != "true" ]]; then
    exit 0
fi


# Install NHC if not already installed in the image
az_nhc_installed_version=$(grep Azure-NHC /opt/azurehpc/test/azurehpc-health-checks/docs/version.log | cut -d':' -f2 | xargs)
az_nhc_target_version="v0.2.9"

if [ "$az_nhc_installed_version" != "$az_nhc_target_version" ] ; then
    if [ -d /opt/azurehpc/test/azurehpc-health-checks ]; then
        rm -rf /opt/azurehpc/test/azurehpc-health-checks
    fi
    mkdir -p /opt/azurehpc/test/
    cd /opt/azurehpc/test/
    git clone https://github.com/Azure/azurehpc-health-checks.git -b $az_nhc_target_version
    cd azurehpc-health-checks
    sed -i 's/AMD/amd/g' customTests/custom-test-setup.sh
    ./install-nhc.sh
fi

. /etc/os-release
case $ID in
    ubuntu)
        LIBEXEDIR=/usr/lib;;
    *) 
        LIBEXEDIR=/usr/libexec;;
esac

# Install azhop-node-offline.sh
cp -v $SCRIPT_DIR/../files/nhc/azhop-node-offline.sh $LIBEXEDIR/nhc/
chmod 755 $LIBEXEDIR/nhc/azhop-node-offline.sh

# # Use our own NHC config files
# NHC_CONFIG_FILE="/etc/nhc/nhc.conf"
# VM_SIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]' | sed 's/standard_//')

# NHC_CONFIG_EXTRA="$SCRIPT_DIR/../files/nhc/nhc_${VM_SIZE}.conf"

# # Use common config for all compute nodes
# if [ -e $NHC_CONFIG_FILE ]; then
#     rm -f ${NHC_CONFIG_FILE}.bak
#     mv $NHC_CONFIG_FILE ${NHC_CONFIG_FILE}.bak
# fi
# cp -fv $SCRIPT_DIR/../files/nhc/nhc_common.conf $NHC_CONFIG_FILE

# # Append VM size specific config if exists
# if [ -e $NHC_CONFIG_EXTRA  ]; then
#     cat $NHC_CONFIG_EXTRA >> $NHC_CONFIG_FILE
# fi

# # Add nvidia-smi health checks for GPU SKUs except NV_v4 as they don't have NVIDIA device
# case $VM_SIZE in
#     nv*v4)
#     ;;
#     nc*|nv*|nd*)
#         echo " * || check_nvsmi_healthmon" >> $NHC_CONFIG_FILE
#     ;;
#     # Check HDR InfiniBand on all HBv2 and HBv3 SKUs
#     hb*v2|hb*v3)
#         echo " * || check_hw_ib 200 mlx5_ib0:1" >> $NHC_CONFIG_FILE
#     ;;
#     hc44rs)
#         echo " * || check_hw_ib 100 mlx5_ib0:1" >> $NHC_CONFIG_FILE
#     ;;

# esac