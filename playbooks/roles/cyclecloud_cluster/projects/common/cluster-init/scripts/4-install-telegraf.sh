#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/../files/azhop-helpers.sh" 
read_os

$script_dir/../files/$os_release/init_telegraf.sh

echo "Configuring global tags"
AZHPC_VMSIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]')
PHYSICAL_HOST=$(strings /var/lib/hyperv/.kvp_pool_3 | grep -A1 PhysicalHostName | head -n 2 | tail -1)
VMSS=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmScaleSetName')
ARRAY=$(jetpack config cyclecloud.node.template)

sed -i "s/__SKU__/${AZHPC_VMSIZE}/g" ../files/telegraf.conf
sed -i "s/__PHYS_HOST__/${PHYSICAL_HOST}/g" ../files/telegraf.conf
sed -i "s/__ARRAY__/${ARRAY}/g" ../files/telegraf.conf

echo "Copy configuration file to use"
TELEGRAF_CONF_DIR=/etc/telegraf
cp ../files/telegraf.conf $TELEGRAF_CONF_DIR/telegraf.conf
chown telegraf:root $TELEGRAF_CONF_DIR/telegraf.conf
chmod 600 $TELEGRAF_CONF_DIR/telegraf.conf

echo "#### Starting Telegraf services:"
systemctl enable telegraf
systemctl restart telegraf
