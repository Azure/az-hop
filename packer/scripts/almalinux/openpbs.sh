#!/bin/bash

BUILD_FROM_SOURCE=yes

if [ "$BUILD_FROM_SOURCE" == "yes" ] ; then
    dnf install -y gcc make rpm-build libtool hwloc-devel \
        libX11-devel libXt-devel libedit-devel libical-devel \
        ncurses-devel perl postgresql-devel postgresql-contrib python2 python2-devel tcl-devel \
        tk-devel swig expat-devel openssl-devel libXext libXft \
        autoconf automake gcc-c++ git

    cd /mnt
    git clone https://github.com/open-mpi/hwloc.git -b v1.11
    cd hwloc
    ./configure --enable-static --enable-embedded-mode
    make
    cd ..
    
    wget -q https://github.com/openpbs/openpbs/releases/download/v19.1.1/pbspro-19.1.1.tar.gz -O pbspro-19.1.1.tar.gz
    tar -xzf pbspro-19.1.1.tar.gz
    cd pbspro-19.1.1/
    ./configure --prefix=/opt/pbs PYTHON=/usr/bin/python2.7 CFLAGS="-I$PWD/../hwloc/include" LDFLAGS="-L$PWD/../src"
    make
    make install

    /opt/pbs/libexec/pbs_postinstall execution
    chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
else
    wget https://github.com/openpbs/openpbs/releases/download/v20.0.1/openpbs_20.0.1.centos_8.zip
    unzip -o openpbs_20.0.1.centos_8.zip
    dnf install epel-release -y
    dnf install -y openpbs_20.0.1.centos_8/openpbs-execution-20.0.1-0.x86_64.rpm jq
    rm -rf openpbs_20.0.1.centos_8.zip
    rm -rf openpbs_20.0.1.centos_8
fi
