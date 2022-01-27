#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/../files/azhop-helpers.sh" 
read_os

$script_dir/../files/$os_release/init_chronyd.sh

if [ -e /dev/ptp_hyperv ]; then
  PTP="ptp_hyperv"
else
  PTP="ptp0"
fi

cat <<EOF >/etc/chrony.conf
driftfile /var/lib/chrony/drift
makestep 1.0 -1
rtcsync
logdir /var/log/chrony
refclock PHC /dev/$PTP poll 3 dpoll -2 offset 0 stratum 2
EOF

chmod 644 /etc/chrony.conf

systemctl enable chronyd
systemctl restart chronyd