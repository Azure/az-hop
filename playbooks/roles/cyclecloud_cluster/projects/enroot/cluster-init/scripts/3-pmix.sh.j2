#!/bin/bash
set -e

# Install PMIx if not present in the image
# if the /opt/pmix/v4 directory is not present, then install PMIx
if [ ! -d /opt/pmix/v4 ]; then
    os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | xargs)
    case $os_release in
        rhel|almalinux)
            dnf -y install autoconf flex libevent-devel git
            ;;
        ubuntu|debian)
            apt-get update
            apt-get install -y git libevent-dev libhwloc-dev autoconf flex make gcc libxml2
            ;;
    esac
    # Build PMIx
    cd /mnt/scratch
    rm -rf openpmix
    git clone --recursive https://github.com/openpmix/openpmix.git
    cd openpmix
    git checkout v4.2.9
    ./autogen.pl
    ./configure --prefix=/opt/pmix/v4
    make -j install
fi

# Exit if Enroot is not in the image
[ -d /etc/enroot ] || exit 0

# Install extra hooks for PMIx
cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d

[ -d /etc/sysconfig ] || mkdir -pv /etc/sysconfig
# Add variables for PMIx
sed -i '/EnvironmentFile/a Environment=PMIX_MCA_ptl=^usock PMIX_MCA_psec=none PMIX_SYSTEM_TMPDIR=/var/empty PMIX_MCA_gds=hash HWLOC_COMPONENTS=-opencl' /usr/lib/systemd/system/slurmd.service
systemctl daemon-reload
