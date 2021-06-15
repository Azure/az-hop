#!/bin/bash
set -e
CURRENT_DATE=`date`
AZHPC_VMSIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]')
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function check_ib_device()
{
    bad_node=0
    case $AZHPC_VMSIZE in
        standard_h16mr|standard_h16r)
            ib_device=$(ifconfig | grep eth1 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
            if [ -n "$ib_device" ]; then
                IB_STATE=$(cat /sys/class/infiniband/*/ports/1/state | awk -F ":" '{print $2}' | xargs)  2>/dev/null
                IB_PHYS_STATE=$(cat /sys/class/infiniband/*/ports/1/phys_state | awk -F ":" '{print $2}'| xargs)  2>/dev/null
                IB_RATE=$(cat /sys/class/infiniband/*/ports/1/rate)  2>/dev/null
                IB_SPEED=$(/sbin/ethtool eth1 | grep "Speed:" | awk '{print $2}'| xargs)  2>/dev/null
            else
                echo "ERROR : No IB devices found"
                bad_node=1
                exit 254
            fi
        ;;

        standard_hc44rs|standard_hb60rs|standard_hb120rs_v2|standard_hb120*rs_v3|standard_nd96asr_v4)
            # Retrieve IB info
            ib_device=$(ifconfig | grep ib0 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
            if [ -n "$ib_device" ]; then
                IB_STATE=$(ibv_devinfo | grep state | xargs | cut -d' ' -f2)
                IB_RATE=$(ibv_devinfo -v | grep active_width | cut -d':' -f2 | xargs | cut -d' ' -f1)
                IB_SPEED=$(ibv_devinfo -v | grep active_speed | cut -d':' -f2 | xargs | cut -d'(' -f1 | xargs)
                IB_PHYS_STATE=$(ibv_devinfo -v | grep phys_state | cut -d':' -f2 | xargs | cut -d' ' -f1)
            else
                echo "ERROR : No IB devices found"
                bad_node=1
                exit 254
            fi
        ;;

        *)
            echo "uncovered VM Size $AZHPC_VMSIZE"
            exit 0
        ;;
    esac

    # Don't call if there is no IB device
    if [ $bad_node -eq 0 ]; then
        check_ib_values $AZHPC_VMSIZE "$IB_STATE" "$IB_RATE" "$IB_SPEED" "$IB_PHYS_STATE"
    fi
}


function check_ib_values()
{
    vmsize=$1
    state=$2
    rate=$3
    speed=$4
    phys_state=$5

    # Read the expected values from the dictionary config file
    dictionary=$(jq '.infiniband[] | select(.sku==$vmsize)' --arg vmsize $vmsize $THIS_DIR/../healthchecks.json)
    expected=$(echo $dictionary | jq -r '.state')
    if [ "$state" != "$expected" ]; then
        echo "ERROR : IB state is $state while expected is $expected"
        exit 254
    fi
    expected=$(echo $dictionary | jq -r '.rate')
    if [ "$rate" != "$expected" ]; then
        echo "ERROR : IB rate is $rate while expected is $expected"
        exit 254
    fi
    expected=$(echo $dictionary | jq -r '.speed')
    if [ "$speed" != "$expected" ]; then
        echo "ERROR : IB speed is $speed while expected is $expected"
        exit 254
    fi
    expected=$(echo $dictionary | jq -r '.phys_state')
    if [ "$phys_state" != "$expected" ]; then
        echo "ERROR : IB physical state is $phys_state while expected is $expected"
        exit 254
    fi

}

# Check IB device only if IB tools are installed
if [ -e /usr/bin/ibv_devinfo ]; then
    check_ib_device
fi

exit 0
