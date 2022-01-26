#!/bin/bash
if ! dpkg -l telegraf; then

  wget -qO- https://repos.influxdata.com/influxdb.key | tee /etc/apt/trusted.gpg.d/influxdb.asc >/dev/null
  source /etc/os-release
  echo "deb https://repos.influxdata.com/${ID} ${VERSION_CODENAME} stable" | tee /etc/apt/sources.list.d/influxdb.list
  apt-get update 
  apt-get install -y telegraf jq

fi

