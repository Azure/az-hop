#!/bin/bash

yum install -y epel-release
yum install -y libglvnd-devel pkgconfig
yum install -y dkms
yum install -y "kernel-devel-uname-r == $(uname -r)"

cat <<EOF >/etc/modprobe.d/nouveau.conf
blacklist nouveau
blacklist lbm-nouveau
EOF

echo "################### INSTALL CUDA"
NVIDIA_DRIVER_VERSION=470.82.01 #510.73.08
CUDA_VERSION=11-4 #11.4.3 #11.7.0
yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
yum clean all
yum -y install nvidia-driver-latest-dkms-$NVIDIA_DRIVER_VERSION 
yum -y install cuda-runtime-$CUDA_VERSION
yum -y install https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/nvidia-libXNVCtrl-$NVIDIA_DRIVER_VERSION-1.el7.x86_64.rpm
yum -y install https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/nvidia-libXNVCtrl-devel-$NVIDIA_DRIVER_VERSION-1.el7.x86_64.rpm
yum -y install https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/nvidia-settings-$NVIDIA_DRIVER_VERSION-1.el7.x86_64.rpm
yum -y install cuda-drivers-$NVIDIA_DRIVER_VERSION

echo "################### INSTALL NVIDIA GRID DRIVERS"
systemctl stop nv_peer_mem.service
systemctl stop nvidia-fabricmanager
rmmod gdrdrv
rmmod drm_kms_helper
nv_hostengine_pid=$(lsof /dev/nvidia0 | tail -n 1 | cut -d' ' -f2)
kill $nv_hostengine_pid
rmmod nvidia_drm nvidia_modeset nvidia

init 3
# Use the direct link which contains the clear version number
# https://download.microsoft.com/download/6/2/5/625e22a0-34ea-4d03-8738-a639acebc15e/NVIDIA-Linux-x86_64-$NVIDIA_DRIVER_VERSION-grid-azure.run
wget -O NVIDIA-Linux-x86_64-grid.run https://download.microsoft.com/download/a/3/c/a3c078a0-e182-4b61-ac9b-ac011dc6ccf4/NVIDIA-Linux-x86_64-$NVIDIA_DRIVER_VERSION-grid-azure.run
chmod +x NVIDIA-Linux-x86_64-grid.run
sudo ./NVIDIA-Linux-x86_64-grid.run -s || exit 1
# Answers are: yes, yes, yes
sudo cp /etc/nvidia/gridd.conf.template /etc/nvidia/gridd.conf

cat <<EOF >>/etc/nvidia/gridd.conf
IgnoreSP=FALSE
EnableUI=FALSE 
EOF
sed -i '/FeatureType=0/d' /etc/nvidia/gridd.conf

echo "Test if nvidia-smi is working"
set -e
nvidia-smi
set +e

echo "################### INSTALL VirtualGL / VNC"
yum groupinstall -y "X Window system"
yum groupinstall -y xfce
yum install -y https://netix.dl.sourceforge.net/project/turbovnc/2.2.5/turbovnc-2.2.5.x86_64.rpm
yum install -y https://cbs.centos.org/kojifiles/packages/python-websockify/0.8.0/13.el7/noarch/python2-websockify-0.8.0-13.el7.noarch.rpm

wget --no-check-certificate "https://virtualgl.com/pmwiki/uploads/Downloads/VirtualGL.repo" -O /etc/yum.repos.d/VirtualGL.repo

yum install -y VirtualGL turbojpeg xorg-x11-apps
/usr/bin/vglserver_config -config +s +f -t

systemctl disable firstboot-graphical
systemctl set-default graphical.target
systemctl isolate graphical.target

cat <<EOF >/etc/rc.d/rc3.d/busidupdate.sh
#!/bin/bash
nvidia-xconfig --enable-all-gpus --allow-empty-initial-configuration -c /etc/X11/xorg.conf --virtual=1920x1200 -s
# https://virtualgl.org/Documentation/HeadlessNV
sed -i '/BusID/a\    Option         "HardDPMS" "false"' /etc/X11/xorg.conf
EOF
chmod +x /etc/rc.d/rc3.d/busidupdate.sh
/etc/rc.d/rc3.d/busidupdate.sh

# browser and codecs
yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
yum -y install firefox ffmpeg ffmpeg-devel

# increase buffer size
cat << EOF >>/etc/sysctl.conf
net.core.rmem_max=2097152
net.core.wmem_max=2097152
EOF
