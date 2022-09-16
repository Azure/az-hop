#!/bin/bash
NHC_SYSCONFIG=/etc

yum install -y https://github.com/mej/nhc/releases/download/1.4.3/lbnl-nhc-1.4.3-1.el7.noarch.rpm

NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/nhc.conf

function nhc_config() {
   NHC_CONFIG_FILE=${NHC_SYSCONFIG}/nhc/nhc.conf
   if ! [[ -f ${NHC_CONFIG_FILE}_orig ]]
   then
      mv ${NHC_CONFIG_FILE} ${NHC_CONFIG_FILE}_orig
      cp ${NHC_CONF_FILE_NEW} ${NHC_CONFIG_FILE}
   else
      echo "Warning: Did not set up NHC config (Looks like it has already been set-up)"
   fi
}

nhc_config
# enable the healthcheck on the node
cp ../files/healthchecks.sh /opt/cycle/jetpack/config/healthcheck.d/healthchecks.sh
cp ../files/healthchecks.json /opt/cycle/jetpack/config/healthchecks.json
chmod 777 /opt/cycle/jetpack/config/healthcheck.d/healthchecks.sh

echo "Restarting healthcheck service"
systemctl restart healthcheck

# force run once on startup
source /opt/cycle/jetpack/system/bin/cyclecloud-env.sh

echo "Run healthcheck"
healthcheck

