#!/bin/bash
set -euox pipefail

CS_CLIENT_URL=https://dvpublicsa.blob.core.windows.net/bits/lustre-cray-2.12.B51.g65b567.zip
CS_CLIENT_ZIP=lustre-cray-2.12.B51.g65b567.zip
CS_MOUNT_PATH=/clusterstor

# Install required OS components
yum groupinstall -y "Development Tools"
yum install -y kernel-devel-$(uname -r) zlib-devel libyaml-devel pdsh

# Build and install Cray Lustre client RPM packages
cd /tmp
wget $CS_CLIENT_URL
unzip $CS_CLIENT_ZIP
rpmbuild --rebuild --without servers --without lustre-tests --define 'configure_args --with-o2ib=no' lustre-*.src.rpm
yum install -y /root/rpmbuild/RPMS/x86_64/{kmod-lustre-client,lustre-client}-2.12.4.4*.x86_64.rpm

# Configure and start Lustre Networking
echo 'options lnet networks=tcp0(eth0)' > /etc/modprobe.d/1net_pri.conf
echo 'options lnet lnet_peer_discovery_disabled=1' >> /etc/modprobe.d/1net_health.conf
systemctl enable lnet
modprobe lnet
lctl network up
lctl list_nids

# Configure Lustre automount
lnetctl net show --net tcp >> /etc/1net.conf
mkdir -py $CS_MOUNT_PATH
mount -t lustre 172.25.10.14@tcp:172.25.10.15@tcp:/lustre4 $CS_MOUNT_PATH
echo "mount -t lustre 172.25.10.14@tcp:172.25.10.15@tcp:/lustre4 $CS_MOUNT_PATH" >> /etc/rc.d/rc.local

chmod +x /etc/rc.d/rc.local
systemctl enable rc-local

# Add client configuration parameters to be set in client
# after Lustre is mounted and make them persistent
1ctl set_param llite.*.max_read_ahead_mb=2048
lctl set_param 1lite.*.max_read_ahead_per_file_mb=2048
lctl set_param osc.*.max_rpcs_in_flight=64
echo '/usr/sbin/lctl set_param llite.*.max_read_ahead_mb=2048' >> /etc/rc.d/rc.local
echo '/usr/sbin/lctl set_param 1lite.*.max_read_ahead_per_file_mb=2048' >> /etc/rc.d/rc.local
echo '/usr/sbin/lctl set_param osc.*.max_rpcs_in_flight=64' >> /etc/rc.d/rc.local
