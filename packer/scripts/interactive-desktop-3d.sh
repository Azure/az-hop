#!/bin/bash

################### INSTALL NVIDIA DRIVERS

yum install -y epel-release
yum install -y dkms
yum install -y "kernel-devel-uname-r == $(uname -r)"

cat <<EOF >/etc/modprobe.d/nouveau.conf
blacklist nouveau
blacklist lbm-nouveau
EOF

wget -O NVIDIA-Linux-x86_64-grid.run https://go.microsoft.com/fwlink/?linkid=874272  
chmod +x NVIDIA-Linux-x86_64-grid.run
sudo ./NVIDIA-Linux-x86_64-grid.run -s
# Answers are: yes, yes, yes
sudo cp /etc/nvidia/gridd.conf.template /etc/nvidia/gridd.conf

BUSID=`nvidia-xconfig --query-gpu-info | awk '/PCI BusID/{print \$4}'`
nvidia-xconfig -a --allow-empty-initial-configuration -c /etc/X11/xorg.conf --busid=$BUSID --virtual=1920x1200 -s

cat <<EOF >>/etc/nvidia/gridd.conf
IgnoreSP=FALSE
EnableUI=FALSE 
EOF
sed -i '/FeatureType=0/d' /etc/nvidia/gridd.conf

cat <<EOF >/etc/rc.d/rc3.d/busidupdate.sh
#!/bin/bash
XCONFIG="/etc/X11/xorg.conf"
OLDBUSID=\`awk '/BusID/{gsub(/"/, "", \$2); print \$2}' \${XCONFIG}\`
NEWBUSID=\`nvidia-xconfig --query-gpu-info | awk '/PCI BusID/{print \$4}'\`

if [[ "${OLDBUSID}" == "${NEWBUSID}" ]] ; then
        echo "NVIDIA BUSID not changed - nothing to do"
else
        echo "NVIDIA BUSID changed from \"${OLDBUSID}\" to \"${NEWBUSID}\": Updating ${XCONFIG}" 
        sed -e 's|BusID.*|BusID          '\"${NEWBUSID}\"'|' -i ${XCONFIG}
fi
EOF
chmod +x /etc/rc.d/rc3.d/busidupdate.sh
/etc/rc.d/rc3.d/busidupdate.sh

################### INSTALL VirtualGL / VNC

yum groupinstall -y "X Window system"
yum groupinstall -y xfce
yum install -y https://netix.dl.sourceforge.net/project/turbovnc/2.2.5/turbovnc-2.2.5.x86_64.rpm
yum install -y https://cbs.centos.org/kojifiles/packages/python-websockify/0.8.0/13.el7/noarch/python2-websockify-0.8.0-13.el7.noarch.rpm

yum install -y VirtualGL turbojpeg xorg-x11-apps
/usr/bin/vglserver_config -config +s +f -t

systemctl disable firstboot-graphical
systemctl set-default graphical.target
systemctl isolate graphical.target

# install CUDA

yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
yum clean all
yum -y install nvidia-driver-latest-dkms cuda
yum -y install cuda-drivers

# browser and codecs
yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
yum -y install firefox ffmpeg ffmpeg-devel

# increase buffer size
cat << EOF >>/etc/sysctl.conf
net.core.rmem_max=2097152
net.core.wmem_max=2097152
EOF
