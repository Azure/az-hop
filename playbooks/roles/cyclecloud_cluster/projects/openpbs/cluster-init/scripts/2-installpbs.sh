#!/bin/bash

if which dpkg; then

  wget https://github.com/openpbs/openpbs/releases/download/v19.1.1/pbspro-19.1.1.tar.gz
  tar -xzf pbspro-19.1.1.tar.gz
  cd pbspro-19.1.1/
  sudo apt-get install -y gcc make libtool libhwloc-dev libx11-dev       libxt-dev libedit-dev libical-dev ncurses-dev perl       postgresql-server-dev-all postgresql-contrib python-dev tcl-dev tk-dev swig       libexpat-dev libssl-dev libxext-dev libxft-dev autoconf       automake
  ./autogen.sh
  ./configure --prefix=/opt/pbs
  make
  make install
  /opt/pbs/libexec/pbs_postinstall
  chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
  /etc/init.d/pbs start

fi

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
