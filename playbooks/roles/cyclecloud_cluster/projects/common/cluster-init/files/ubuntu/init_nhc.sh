#!/bin/bash

cd /root
if [ ! -f /usr/sbin/nhc ] || [ ! -d /etc/nhc ] ; then
    git clone https://github.com/mej/nhc.git -b 1.4.3
    cd nhc
    ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/lib
    #make test
    make install
fi