#!/bin/bash
CURRENT_DATE=`date`
AZHPC_VMSIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]')
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PHYSICAL_HOST=$(strings /var/lib/hyperv/.kvp_pool_3 | grep -A1 PhysicalHostName | head -n 2 | tail -1)

function log()
{
    timestamp=$(date -u "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp $1" >> /opt/cycle/jetpack/logs/check_stuff.log 
}

function check_ib_device()
{
    log "Checking IB Devices"
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
                1>&2 echo "ERROR : No IB devices found - $(hostname) - $PHYSICAL_HOST"
                bad_node=1
                exit 254
            fi
        ;;

        standard_hc44rs|standard_hb60rs|standard_hb120rs_v2|standard_hb120*rs_v3|standard_nd96asr_v4)
            # Retrieve IB info
            ib_device=$(ifconfig 2>/dev/null | grep ib0 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
            if [ -n "$ib_device" ]; then
                IB_STATE=$(ibv_devinfo -d mlx5_ib0 | grep state | xargs | cut -d' ' -f2)
                IB_RATE=$(ibv_devinfo -d mlx5_ib0 -v | grep active_width | cut -d':' -f2 | xargs | cut -d' ' -f1)
                IB_SPEED=$(ibv_devinfo -d mlx5_ib0 -v | grep active_speed | cut -d':' -f2 | xargs | cut -d'(' -f1 | xargs)
                IB_PHYS_STATE=$(ibv_devinfo -d mlx5_ib0 -v | grep phys_state | cut -d':' -f2 | xargs | cut -d' ' -f1)
            else
                1>&2 echo "ERROR : No IB devices found - $(hostname) - $PHYSICAL_HOST"
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
        1>&2 echo "ERROR : IB state is $state while expected is $expected - $(hostname) - $PHYSICAL_HOST"
        exit 254
    fi
    expected=$(echo $dictionary | jq -r '.rate')
    if [ "$rate" != "$expected" ]; then
        1>&2 echo "ERROR : IB rate is $rate while expected is $expected - $(hostname) - $PHYSICAL_HOST"
        exit 254
    fi
    expected=$(echo $dictionary | jq -r '.speed')
    if [ "$speed" != "$expected" ]; then
        1>&2 echo "ERROR : IB speed is $speed while expected is $expected - $(hostname) - $PHYSICAL_HOST"
        exit 254
    fi
    expected=$(echo $dictionary | jq -r '.phys_state')
    if [ "$phys_state" != "$expected" ]; then
        1>&2 echo "ERROR : IB physical state is $phys_state while expected is $expected - $(hostname) - $PHYSICAL_HOST"
        exit 254
    fi

}

function check_gpu()
{
    log "Checking GPU"
    case $AZHPC_VMSIZE in
        standard_nc*|standard_nv*|standard_nd*)
            nvidia-smi || exit 254
        ;;
    esac
}

# This function check if the node can resolve reverse DNS on his hostname
# If not and if Cycle is renaming the host (standalone DNS), then run a jetpack converge
function check_hostname()
{
    log "Check Hostname - start"
    local name=$(hostname)
    name=${name,,}
    local standalone_dns=$(/opt/cycle/jetpack/bin/jetpack config cyclecloud.hosts.standalone_dns.enabled)
    # Check if hostname has been renamed correctly
    log "hostname is $name; standalone_dns=$standalone_dns"
    if [ "${standalone_dns,,}" == "true" ]; then
        # Check if hostname start with ip
        if [ "${name:0:3}" != "ip-" ]; then
            # Rerun jetpack converge
            log "hostname doesn't start with ip-"
            /opt/cycle/jetpack/bin/jetpack converge > /dev/null
            1>&2 echo "$name was not renamed correctly - rerunning jetpack converge"
        fi
    fi
    # Check if hostname can be resolved
    name=$(hostname)
    log "hostname is $name - testing nslookup"
    nslookup $name > /dev/null
    if [ $? -ne 0 ]; then
        if [ "${standalone_dns,,}" == "true" ]; then
            log "failed to resove hostname rerun jetpack converge"
            # Rerun jetpack converge
            /opt/cycle/jetpack/bin/jetpack converge > /dev/null
            1>&2 echo "$name was unable to resolve it's name - rerunning jetpack converge"
        fi
    fi
    log "Check Hostname - end"
}

function check_domain_joined()
{
    local delay=15
    local n=1
    local max_retry=3

    while true; do
        realm list | grep active-directory 2>/dev/null
        if [ $? -eq 1 ]; then
            if [[ $n -le $max_retry ]]; then
                echo "Failed to check if node is domain joined -  Attempt $n/$max_retry:"
                sleep $delay
                ((n++))
            else
                1>&2 echo "Node $(hostname) is not domain joined"
                exit 254
            fi
        else
            break
        fi
    done
}

# Check IB device only if IB tools are installed
if [ -e /usr/bin/ibv_devinfo ]; then
    check_ib_device
fi

check_gpu
#check_hostname
# Removing domain join check as it first run before the node is domain joined
#check_domain_joined

exit 0
