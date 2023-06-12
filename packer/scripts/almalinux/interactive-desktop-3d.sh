#!/bin/bash

dnf install -y epel-release
dnf install -y libglvnd-devel pkgconfig
dnf install -y dkms

cat <<EOF >/etc/modprobe.d/nouveau.conf
blacklist nouveau
blacklist lbm-nouveau
EOF

echo "################### INSTALL NVIDIA GRID DRIVERS"
echo "################### UNLOAD NVIDIA MODULES"
systemctl stop nv_peer_mem.service
systemctl stop nvidia-fabricmanager
systemctl stop dcgm.service
systemctl stop nvidia-dcgm.service

rmmod gdrdrv
rmmod nvidia_drm
rmmod drm_kms_helper
lsof /dev/nvidia0
# nv_hostengine_pid=$(lsof /dev/nvidia0 | tail -n 1 | cut -d' ' -f2)
# echo "Kill process $nv_hostengine_pid"
# sudo kill -9 $nv_hostengine_pid
#lsof /dev/nvidia0
rmmod nvidia_modeset
rmmod nvidia_uvm
rmmod nvidia
rmmod drm

#init 3
lsmod

# remove previous kernel modules
sudo /sbin/dkms status
sudo /sbin/dkms status | grep nvidia | cut -d',' -f1 | xargs -I{} /sbin/dkms remove {} --all
#rm -f /lib/modules/$(uname -r)/kernel/drivers/video/*.ko

# Use the direct link which contains the clear version number
# Check which latest version to use from https://github.com/Azure/azhpc-extensions/blob/master/NvidiaGPU/resources.json
wget -O /mnt/NVIDIA-Linux-x86_64-grid.run https://download.microsoft.com/download/6/b/d/6bd2850f-5883-4e2a-9a35-edbd3dd6808c/NVIDIA-Linux-x86_64-525.105.17-grid-azure.run
chmod +x /mnt/NVIDIA-Linux-x86_64-grid.run
sudo /mnt/NVIDIA-Linux-x86_64-grid.run -s --no-check-for-alternate-installs
cat /var/log/nvidia-installer.log
set -e
/sbin/dkms install --no-depmod -m nvidia -v 525.105.17 -k $(uname -r) --force
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
dnf groupinstall -y xfce
dnf remove -y xfce4-screensaver
dnf install -y https://kumisystems.dl.sourceforge.net/project/turbovnc/3.0.3/turbovnc-3.0.3.x86_64.rpm
dnf install -y python3-websockify

wget --no-check-certificate "https://virtualgl.com/pmwiki/uploads/Downloads/VirtualGL.repo" -O /etc/yum.repos.d/VirtualGL.repo

yum install -y VirtualGL turbojpeg xorg-x11-apps
set -e
/usr/bin/vglserver_config -config +s +f -t
set +e
systemctl disable firstboot-graphical
systemctl set-default graphical.target
systemctl isolate graphical.target

cat <<EOF >/etc/rc.d/rc3.d/busidupdate.sh
#!/bin/bash
nvidia-xconfig --enable-all-gpus --allow-empty-initial-configuration -c /etc/X11/xorg.conf --virtual=1920x1200 -s
# https://virtualgl.org/Documentation/HeadlessNV
sed -i '/NVIDIA/a\    Option         "HardDPMS" "false"' /etc/X11/xorg.conf
EOF
chmod +x /etc/rc.d/rc3.d/busidupdate.sh
/etc/rc.d/rc3.d/busidupdate.sh

# Create a vglrun alias
cat <<EOF >/etc/profile.d/vglrun.sh 
#!/bin/bash
# Set the vglrun alias to pickup a GPU device based on the noVNC port so that each session is landing on a different GPU, modulo the number of GPU devices.
ngpu=\$(lspci | grep NVIDIA | wc -l)
alias vglrun='/usr/bin/vglrun -d :0.\$(( \${port:-0} % \${ngpu:-1}))'
EOF

# browser and codecs
dnf install -y https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm
dnf -y install firefox ffmpeg ffmpeg-devel

# Install archive manager
dnf install -y file-roller
#dnf -y install xarchiver
#rm -f /usr/libexec/thunar-archive-plugin/gnome-file-roller.tap
#ln -s /usr/libexec/thunar-archive-plugin/xarchiver.tap /usr/libexec/thunar-archive-plugin/gnome-file-roller.tap
#update-desktop-database /usr/share/applications

# increase buffer size
cat << EOF >>/etc/sysctl.conf
net.core.rmem_max=2097152
net.core.wmem_max=2097152
EOF
