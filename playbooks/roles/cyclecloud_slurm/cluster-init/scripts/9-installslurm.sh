#!/bin/bash

# install SLURM rpms when not in custom image
if [ ! -d "/etc/slurm" ]; then
  echo "Installing Slurm RPMs"
  yum install -y epel-release
  yum install -y munge jq
  yum install -y /anfhome/slurm/rpms/slurm-2*.rpm /anfhome/slurm/rpms/slurm-slurmd-*.rpm
fi

mkdir -p /etc/munge/
cp /anfhome/slurm/config/munge.key /etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
systemctl restart munge

groupadd -g 983 slurm
useradd -g slurm -u 983 slurm

ln -s /anfhome/slurm/config /sched
mkdir -p /etc/slurm/
mkdir -p /var/spool/slurmd/
mkdir -p /var/log/slurmd/
chown slurm:slurm /var/spool/slurmd
chown slurm:slurm /var/log/slurmd
ln -s /sched/slurm.conf /etc/slurm/slurm.conf
ln -s /sched/cyclecloud.conf /etc/slurm/cyclecloud.conf
ln -s /sched/cgroup.conf /etc/slurm/cgroup.conf
ln -s /sched/gres.conf /etc/slurm/gres.conf
ln -s /sched/topology.conf /etc/slurm/topology.conf

systemctl restart slurmd
