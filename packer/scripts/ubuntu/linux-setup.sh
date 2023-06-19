#!/bin/bash
echo " ********************************************************************************** "
echo " *                                                                                * "
echo " *     LINUX SETUP                                                                * "
echo " *                                                                                * "
echo " ********************************************************************************** "
packages="nfs-common sssd libsss-simpleifp0 sssd-dbus sssd-tools realmd oddjob oddjob-mkhomedir adcli samba-common krb5-user ldap-utils packagekit resolvconf jq chrony netcat"

apt-get clean -y
apt-get autoremove -y
apt -y update
# this export is needed to stop input for krb5-user
export DEBIAN_FRONTEND=noninteractive
apt-get install -y $packages

# Disable requiretty to allow run sudo within scripts
sed -i -e 's/Defaults    requiretty.*/ #Defaults    requiretty/g' /etc/sudoers

cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
*               hard    nofile          65535
*               soft    nofile          65535
*               hard    stack           unlimited
*               soft    stack           unlimited
EOF

# Install azcopy
cd /usr/local/bin
wget -q https://aka.ms/downloadazcopy-v10-linux -O - | tar zxf - --strip-components 1 --wildcards '*/azcopy'
chmod 755 /usr/local/bin/azcopy

# Create a symlink for the Modules to allow compatibility with the HPC CentOS image which have Modules in capital case
if [ ! -d /usr/share/Modules/modulefiles ]; then
    ln -s /usr/share/modules /usr/share/Modules
fi

# Add I_MPI_HYDRA_BOOTSTRAP=ssh in the IMPI module otherwise it will break how PBS launch jobs
if ! grep I_MPI_HYDRA_BOOTSTRAP /usr/share/modules/modulefiles/mpi/impi-2021 ; then
    echo "setenv I_MPI_HYDRA_BOOTSTRAP ssh" >> /usr/share/modules/modulefiles/mpi/impi-2021
fi
