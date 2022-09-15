#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/../files/azhop-helpers.sh" 

cd /root
if [ ! -f /usr/sbin/nhc ] || [ ! -d /etc/nhc ] ; then
    git clone https://github.com/mej/nhc.git
    cd nhc
    ./autogen.sh
#    if is_centos ; then
    ./configure --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/libexec
#    fi
    make test
    make install
fi

nhc_config_file="/etc/nhc/nhc.conf"
vm_size=`jetpack config azure.metadata.compute.vmSize | tr '[:upper:]' '[:lower:]' | sed 's/standard_//'`
nhc_config_extra="$script_dir/../files/nhc/nhc_${vm_size}.conf"

# Use common config for all compute nodes
[ -a $nhc_config_file ] && rm -f ${nhc_config_file}.bak && mv $nhc_config_file ${nhc_config_file}.bak
cp -fv $script_dir/../files/nhc/nhc_common.conf $nhc_config_file
# Append VM size specific config if exists
[ -a $nhc_config_extra  ] && cat $nhc_config_extra >> $nhc_config_file

# Run the NHC on startup
/usr/sbin/nhc
