#!/bin/bash

ENROOT_VERSION_FULL=${1:-3.4.0-2}
ENROOT_VERSION=${ENROOT_VERSION_FULL%-*}

arch=$(uname -m)
dnf install -y epel-release
rpm -q enroot || dnf install -y https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot-${ENROOT_VERSION_FULL}.el8.${arch}.rpm
rpm -q enroot+caps || dnf install -y https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot+caps-${ENROOT_VERSION_FULL}.el8.${arch}.rpm

# Install NVIDIA container support
#DIST=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/centos8/libnvidia-container.repo > /etc/yum.repos.d/libnvidia-container.repo

dnf -y makecache
dnf -y install libnvidia-container-tools

# Add kernel boot parameters
grep user.max_user_namespaces /etc/sysctl.conf || echo 'user.max_user_namespaces = 1417997' >> /etc/sysctl.conf
grep namespace.unpriv_enable /etc/default/grub || sed -i.bak 's/\(GRUB_CMDLINE_LINUX.*\)"$/\1 namespace.unpriv_enable=1 user_namespace.enable=1 vsyscall=emulate"/' /etc/default/grub
[ -e /boot/grub2/grub.cfg ] && grub2-mkconfig -o /boot/grub2/grub.cfg
[ -e /boot/efi/EFI/centos/grub.cfg ] && grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

enroot version
