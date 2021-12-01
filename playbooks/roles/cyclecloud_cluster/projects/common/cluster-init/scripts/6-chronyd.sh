#!/bin/bash

if which dpkg; then
  if ! dpkg -l chrony; then
    apt-get install -y chrony
  fi
fi

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
refclock PHC /dev/$PTP poll 3 dpoll -2 offset 0
EOF

chmod 644 /etc/chrony.conf

systemctl enable chronyd
systemctl start chronyd