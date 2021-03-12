#!/bin/bash

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
  local delay=10
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

# install pbs rpms when not in custom image
if [ ! -f "/etc/pbs.conf" ]; then
  echo "Downloading PBS RPMs"
  wget -q https://github.com/PBSPro/pbspro/releases/download/v19.1.1/pbspro_19.1.1.centos7.zip
  unzip -o pbspro_19.1.1.centos7.zip
  echo "Installing PBS RPMs"
  yum install -y epel-release
  yum install -y pbspro_19.1.1.centos7/pbspro-execution-19.1.1-0.x86_64.rpm jq
fi

echo "Configuring PBS"

sed -i 's/CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME/scheduler/' /etc/pbs.conf
sed -i 's/CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME/scheduler/' /var/spool/pbs/mom_priv/config

echo "Register node"
retry /opt/pbs/bin/qmgr -c "c n $(hostname)"

echo "Set slot_type"
/opt/pbs/bin/qmgr -c "s n $(hostname) resources_available.slot_type=$(jetpack config pbspro.slot_type)" || exit 1

# properly set grouping for pcs/htc jobs
echo "properly set grouping for pcs/htc jobs"
if [ `jetpack config pbspro.is_grouped` == "False" ]; then
  /opt/pbs/bin/qmgr -c "s n $(hostname) resources_available.ungrouped=true" || exit 1
else
  /opt/pbs/bin/qmgr -c "s n $(hostname) resources_available.ungrouped=false" || exit 1
fi

echo "Set the group_id with the vmScaleSetName"
poolName=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmScaleSetName')
/opt/pbs/bin/qmgr -c "s n $(hostname) resources_available.group_id=${poolName}" || exit 1

systemctl restart pbs || exit 1
echo "PBS Restarted"
