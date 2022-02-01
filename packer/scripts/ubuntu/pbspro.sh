#!/bin/bash
echo " ********************************************************************************** "
echo " *                                                                                * "
echo " *     PBS PRO                                                                    * "
echo " *                                                                                * "
echo " ********************************************************************************** "

cd /mnt
wget -q https://github.com/openpbs/openpbs/releases/download/v19.1.1/pbspro-19.1.1.tar.gz -O pbspro-19.1.1.tar.gz
tar -xzf pbspro-19.1.1.tar.gz
cd pbspro-19.1.1/

apt-get install -y gcc make libtool libhwloc-dev libx11-dev libxt-dev libedit-dev libical-dev ncurses-dev perl postgresql-server-dev-all postgresql-contrib python-dev tcl-dev tk-dev swig libexpat-dev libssl-dev libxext-dev libxft-dev autoconf automake
./autogen.sh
./configure --prefix=/opt/pbs PYTHON=/usr/bin/python2.7
make
make install

/opt/pbs/libexec/pbs_postinstall execution
chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
