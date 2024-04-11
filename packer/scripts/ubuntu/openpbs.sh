#!/bin/bash
echo " ********************************************************************************** "
echo " *                                                                                * "
echo " *     PBS PRO                                                                    * "
echo " *                                                                                * "
echo " ********************************************************************************** "

cd /mnt

apt install libpq5 -y
wget -q https://vcdn.altair.com/rl/OpenPBS/openpbs_22.05.11.ubuntu_20.04.zip
unzip -o openpbs_22.05.11.ubuntu_20.04.zip
dpkg -i --force-overwrite --force-confnew ./openpbs_22.05.11.ubuntu_20.04/openpbs-execution_22.05.11-1_amd64.deb
rm -rf openpbs_22.05.11.ubuntu_20.04
rm -f openpbs_22.05.11.ubuntu_20.04.zip

#apt-get install -y gcc make libtool libhwloc-dev libx11-dev libxt-dev libedit-dev libical-dev ncurses-dev perl postgresql-server-dev-all postgresql-contrib python-dev tcl-dev tk-dev swig libexpat-dev libssl-dev libxext-dev libxft-dev autoconf automake
#
#wget -q https://github.com/openpbs/openpbs/releases/download/v19.1.1/pbspro-19.1.1.tar.gz -O pbspro-19.1.1.tar.gz
#tar -xzf pbspro-19.1.1.tar.gz
#
#if [ "$(dpkg -s libhwloc-dev| grep Version| sed 's/^[^0-9]*\([0-9]\).*$/\1/')" != "1" ]; then
#    git clone https://github.com/open-mpi/hwloc.git -b v1.11
#    cd hwloc
#    ./autogen.sh
#    ./configure --enable-static --enable-embedded-mode
#    make
#    cd ..
#
#    cd pbspro-19.1.1/
#    ./autogen.sh
#    ./configure --prefix=/opt/pbs PYTHON=/usr/bin/python2.7 CFLAGS="-I$PWD/../hwloc/include" LDFLAGS="-L$PWD/../src"
#    make
#    make install
#else
#    cd pbspro-19.1.1/
#    ./autogen.sh
#    ./configure --prefix=/opt/pbs PYTHON=/usr/bin/python2.7
#    make
#    make install
#fi
#
#/opt/pbs/libexec/pbs_postinstall execution
#chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
