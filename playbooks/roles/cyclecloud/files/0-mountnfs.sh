#!/bin/bash

yum install nfs-utils -y

mkdir /anfhome
mount 10.0.2.4:/home-dD7SAvQF /anfhome 

setsebool -P use_nfs_home_dirs 1
