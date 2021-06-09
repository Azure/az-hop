#!/bin/bash

if [ ! -e /etc/yum.repos.d/influxdb.repo ]; then
echo "#### Configuration repo for InfluxDB:"
cat <<EOF | tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/centos/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF
fi

if ! rpm -q telegraf; then
  echo "#### Telegraf Installation:"
  yum -y install https://dl.influxdata.com/telegraf/releases/telegraf-1.18.2-1.x86_64.rpm
fi

echo "Configuring global tags"
AZHPC_VMSIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]')
PHYSICAL_HOST=$(strings /var/lib/hyperv/.kvp_pool_3 | grep -A1 PhysicalHostName | head -n 2 | tail -1)

sed -i "s/__SKU__/${AZHPC_VMSIZE}/g" ../files/telegraf.conf
sed -i "s/__PHYS_HOST__/${PHYSICAL_HOST}/g" ../files/telegraf.conf

echo "Copy configuration file to use"
TELEGRAF_CONF_DIR=/etc/telegraf
cp ../files/telegraf.conf $TELEGRAF_CONF_DIR/telegraf.conf
chown telegraf:root $TELEGRAF_CONF_DIR/telegraf.conf
chmod 600 $TELEGRAF_CONF_DIR/telegraf.conf

echo "#### Starting Telegraf services:"
systemctl start telegraf
systemctl enable telegraf

