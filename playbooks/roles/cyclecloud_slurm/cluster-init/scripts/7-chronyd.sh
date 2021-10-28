#!/bin/bash

cat <<EOF >/etc/chrony.conf
server ondemand
driftfile /var/lib/chrony/drift
makestep 1.0 -1
rtcsync
logdir /var/log/chrony
refclock PHC /dev/ptp_hyperv poll 3 dpoll -2 offset 0
EOF
chmod 644 /etc/chrony.conf

systemctl enable chronyd
systemctl start chronyd