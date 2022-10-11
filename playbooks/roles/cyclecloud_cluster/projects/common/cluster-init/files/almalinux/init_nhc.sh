#!/bin/bash
rpm -q lbnl-nhc || dnf install -y "https://github.com/mej/nhc/releases/download/1.4.3/lbnl-nhc-1.4.3-1.el7.noarch.rpm"
