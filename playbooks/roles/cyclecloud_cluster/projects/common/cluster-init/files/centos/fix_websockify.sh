#!/bin/bash

# If websockify 0.8.0 is installed, remove it and install release 0.10.0
grep "0.8.0" /usr/bin/websockify
if [ $? -eq 0 ]; then
    yum remove -y python2-websockify
    yum install -y https://yum.osc.edu/ondemand/3.0/compute/el7/x86_64/python3-websockify-0.10.0-1.el7.noarch.rpm
fi
