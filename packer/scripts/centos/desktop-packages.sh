#!/bin/bash

echo "Install QT5 runtime"
yum install -y qt5-qtbase-gui qt5-qtscript qt5-qtsvg

echo "Add Motif"
yum install -y motif motif-devel

echo "Additional packages for Ansys Workbench"
yum install -y libXScrnSaver redhat-lsb-core openssl11-libs libpng12 libgfortran5 libcurl-devel json-c-devel