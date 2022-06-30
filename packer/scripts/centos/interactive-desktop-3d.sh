#!/bin/bash

yum install -y epel-release
yum install -y libglvnd-devel pkgconfig
yum install -y dkms
yum install -y "kernel-devel-uname-r == $(uname -r)"

cat <<EOF >/etc/modprobe.d/nouveau.conf
blacklist nouveau
blacklist lbm-nouveau
EOF


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

echo "################### INSTALL CUDA"
NVIDIA_DRIVER_VERSION=460.32.03
CUDA_VERSION=11-2
yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
yum clean all
yum -y install nvidia-driver-latest-dkms-$NVIDIA_DRIVER_VERSION cuda-$CUDA_VERSION
yum -y install cuda-drivers-$NVIDIA_DRIVER_VERSION

# browser and codecs
yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
yum -y install firefox ffmpeg ffmpeg-devel

# increase buffer size
cat << EOF >>/etc/sysctl.conf
net.core.rmem_max=2097152
net.core.wmem_max=2097152
EOF

echo "################### INSTALL NVIDIA GRID DRIVERS"

init 3
# Use the direct link which contains the clear version number
wget -O NVIDIA-Linux-x86_64-grid.run https://download.microsoft.com/download/9/5/c/95c667ff-ab95-4c56-89e0-e13e9a76782d/NVIDIA-Linux-x86_64-$NVIDIA_DRIVER_VERSION-grid-azure.run
chmod +x NVIDIA-Linux-x86_64-grid.run
sudo ./NVIDIA-Linux-x86_64-grid.run -s
# Answers are: yes, yes, yes
sudo cp /etc/nvidia/gridd.conf.template /etc/nvidia/gridd.conf

cat <<EOF >>/etc/nvidia/gridd.conf
IgnoreSP=FALSE
EnableUI=FALSE 
EOF
sed -i '/FeatureType=0/d' /etc/nvidia/gridd.conf

cat <<EOF >/etc/rc.d/rc3.d/busidupdate.sh
#!/bin/bash
nvidia-xconfig --enable-all-gpus --allow-empty-initial-configuration -c /etc/X11/xorg.conf --virtual=1920x1200 -s
# https://virtualgl.org/Documentation/HeadlessNV
sed -i '/BusID/a\    Option         "HardDPMS" "false"' /etc/X11/xorg.conf
EOF
chmod +x /etc/rc.d/rc3.d/busidupdate.sh
/etc/rc.d/rc3.d/busidupdate.sh

echo "Test if nvidia-smi is working"
set -e
nvidia-smi
