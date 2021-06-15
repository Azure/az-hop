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
        sleep_time=$((delay*n))
        echo "Command failed. Attempt $n/$max. Wait for $sleep_time seconds"
        sleep $sleep_time;
        ((n++))
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
sed -i "s/^if /#if /g" /opt/pbs/lib/init.d/limits.pbs_mom
sed -i "s/^fi/#fi /g" /opt/pbs/lib/init.d/limits.pbs_mom

systemctl restart pbs || exit 1
echo "PBS Restarted"
