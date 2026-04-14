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

# ---- Diagnostics: check GPU hardware before driver install ----
echo "################### PRE-INSTALL GPU DIAGNOSTICS"
echo "Running kernel: $(uname -r)"
echo "Available kernel headers:"
dpkg -l | grep linux-headers | grep -i azure || echo "  (none found)"
echo "PCI GPU devices:"
lspci | grep -iE '3d|vga|display|nvidia' || echo "  WARNING: No GPU device found via lspci!"
echo "Existing NVIDIA kernel modules:"
lsmod | grep nvidia || echo "  (none loaded)"
echo "DKMS status:"
dkms status 2>/dev/null || echo "  (dkms not available)"
echo "################### END PRE-INSTALL DIAGNOSTICS"

# Abort early if no GPU hardware is detected
if ! lspci | grep -iqE 'nvidia|3d controller|vga.*nvidia'; then
    echo "ERROR: No NVIDIA GPU detected in lspci output. The VM SKU may not have a GPU."
    echo "Full lspci output:"
    lspci
    exit 1
fi

# Ensure kernel headers match the running kernel for NVIDIA driver compilation
apt-get install -y linux-headers-$(uname -r)

# Remove pre-existing NVIDIA DKMS modules from the base image to avoid conflicts
dkms status | grep nvidia | cut -d',' -f1 | while read -r mod; do
    echo "Removing DKMS module: $mod"
    dkms remove "$mod" --all 2>/dev/null || true
done

# Check https://github.com/Azure/azhpc-extensions/ for the latest NVIDIA GRID driver supported by Azure and compatible with the Linux kernel version of the image. The link is usually in the release notes of the extension.
# NOTE: The FwLink https://go.microsoft.com/fwlink/?linkid=874272 points to the latest GRID driver (570.x+),
# which dropped support for Maxwell GPUs (Tesla M60, NVv3-series). Pin to 535.161.08 (vGPU 16.5),
# the last GRID version supporting Tesla M60.
GRID_DRIVER_URL="https://download.microsoft.com/download/8/d/a/8da4fb8e-3a9b-4e6a-bc9a-72ff64d7a13c/NVIDIA-Linux-x86_64-535.161.08-grid-azure.run"
wget -O NVIDIA-Linux-x86_64-grid.run "$GRID_DRIVER_URL"
chmod +x NVIDIA-Linux-x86_64-grid.run
./NVIDIA-Linux-x86_64-grid.run -s

# ---- Post-install diagnostics ----
echo "################### POST-INSTALL DIAGNOSTICS"
echo "nvidia-installer log (last 30 lines):"
tail -30 /var/log/nvidia-installer.log 2>/dev/null || echo "  (no installer log found)"
echo "Attempting to load nvidia kernel module:"
modprobe nvidia 2>&1 || echo "  WARNING: modprobe nvidia failed"
echo "Loaded NVIDIA modules:"
lsmod | grep nvidia || echo "  WARNING: No nvidia modules loaded!"
echo "NVIDIA device nodes:"
ls -la /dev/nvidia* 2>/dev/null || echo "  WARNING: No /dev/nvidia* device nodes found"
echo "dmesg nvidia messages (last 20):"
dmesg | grep -i nvidia | tail -20 || echo "  (none)"
echo "################### END POST-INSTALL DIAGNOSTICS"

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

apt-get -s dist-upgrade | grep "^Inst" | grep -i securi | awk -F " " {'print $2'} | xargs apt-get -y install
