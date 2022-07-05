#!/bin/bash

echo "Install QT5 runtime"
yum install -y qt5-qtbase-gui qt5-qtscript qt5-qtsvg

echo "Install ResInsight"
echo sslverify=0 >>/etc/yum.conf
yum-config-manager --add-repo https://opm-project.org/package/opm.repo
yum install -y resinsight resinsight-octave
sed -i 's/^sslverify=0/sslverify=1/' /etc/yum.conf

echo "Add Motif"
yum install -y motif motif-devel
