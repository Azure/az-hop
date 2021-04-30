#!/bin/bash

echo "Install QT5 runtime"
yum install -y qt5-qtbase-gui qt5-qtscript qt5-qtsvg

echo "Install ResInsight"
yum-config-manager --add-repo https://opm-project.org/package/opm.repo
yum install -y resinsight resinsight-octave
