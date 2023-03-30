#!/bin/bash

cd /mnt

apt-get update
apt-get install -y libglvnd-dev

echo "################### UNLOAD NVIDIA MODULES"

systemctl stop nv_peer_mem.service
systemctl stop nvidia-fabricmanager
systemctl stop dcgm

# Prevent DCGM from restarting while NVIDIA driver is installed
systemctl disable dcgm

rmmod gdrdrv
rmmod hyperv_drm
rmmod nvidia_drm
rmmod drm_kms_helper
rmmod nvidia_modeset
rmmod nvidia

echo "################### INSTALL NVIDIA GRID DRIVERS"

wget -O NVIDIA-Linux-x86_64-grid.run https://go.microsoft.com/fwlink/?linkid=874272  
chmod +x NVIDIA-Linux-x86_64-grid.run
./NVIDIA-Linux-x86_64-grid.run -s

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

# Reenable DCGM
systemctl enable dcgm

echo "################### INSTALL VirtualGL / VNC"

DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4
apt-get remove -y gdm3
dpkg-reconfigure lightdm

# Install TurboVNC
wget https://netix.dl.sourceforge.net/project/turbovnc/3.0.3/turbovnc_3.0.3_amd64.deb
dpkg -i turbovnc_3.0.3_amd64.deb

apt install libegl1-mesa
# Install VirtualGL
wget https://kumisystems.dl.sourceforge.net/project/virtualgl/3.1/virtualgl_3.1_amd64.deb
dpkg -i virtualgl_3.1_amd64.deb

apt-get install -y websockify

apt-get install -y libturbojpeg

/usr/bin/vglserver_config -config +s +f -t

systemctl set-default graphical.target
systemctl isolate graphical.target

cat <<EOF >/etc/rc3.d/busidupdate.sh
#!/bin/bash
nvidia-xconfig --enable-all-gpus --allow-empty-initial-configuration -c /etc/X11/xorg.conf --virtual=1920x1200 -s
# https://virtualgl.org/Documentation/HeadlessNV
sed -i '/BusID/a\    Option         "HardDPMS" "false"' /etc/X11/xorg.conf
EOF
chmod +x /etc/rc3.d/busidupdate.sh
/etc/rc3.d/busidupdate.sh

# Create a vglrun alias
cat <<EOF >/etc/profile.d/vglrun.sh 
#!/bin/bash
# Set the vglrun alias to pickup a GPU device based on the noVNC port so that each session is landing on a different GPU, modulo the number of GPU devices.
ngpu=\$(lspci | grep NVIDIA | wc -l)
alias vglrun='/usr/bin/vglrun -d :0.\$(( \${port:-0} % \${ngpu:-1}))'
EOF

apt-get install -y firefox ffmpeg

# increase buffer size
cat << EOF >>/etc/sysctl.conf
net.core.rmem_max=2097152
net.core.wmem_max=2097152
EOF

