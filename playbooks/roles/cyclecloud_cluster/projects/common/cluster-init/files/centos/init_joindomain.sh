#!/bin/bash
packages="sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python"

if ! rpm -q $packages; then
  echo "Installing packages $packages" 
  yum install -y $packages
  echo "Restart dbus systemd-logind"
  systemctl restart dbus
  systemctl restart systemd-logind
fi

echo "Update nameserver"
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/azure-dns
if ! grep "RES_OPTIONS" /etc/sysconfig/network; then
  echo "RES_OPTIONS=\"timeout:1 attempts:5\"" >> /etc/sysconfig/network
fi

function enforce_hostname() {
  local system_hostname=$1
  local target_hostname=$2

  # ensure the correct hostname (update if necessary)
  echo "ensure the correct hostname (update if necessary)"

  if [ "$system_hostname" != "$target_hostname" ]; then
    logger -s "Warning: incorrect hostname ($system_hostname), it should be $target_hostname, updating"
    hostname $target_hostname
  fi
  if grep -i $system_hostname /etc/hosts; then
    logger -s "Warning: incorrect hostname ($system_hostname) in /etc/hosts, updating"
    sed -i "s/$system_hostname/$target_hostname/ig" /etc/hosts
  fi
  etc_hostname=$(</etc/hostname)
  if [ "$etc_hostname" != "$target_hostname" ]; then
    logger -s "Warning: incorrect /etc/hostname ($etc_hostname), it should be $target_hostname, updating"
    echo $target_hostname > /etc/hostname
  fi
  eth0_hostname=$(grep DHCP_HOSTNAME /etc/sysconfig/network-scripts/ifcfg-eth0 | cut -d'=' -f2)
  if [ "$eth0_hostname" != "$target_hostname" ]; then
    logger -s "Warning: incorrect DHCP_HOSTNAME in /etc/sysconfig/network-scripts/ifcfg-eth0 ($etc_hostname), it should be $target_hostname, updating"
    sed -i "s/^DHCP_HOSTNAME=.*\$/DHCP_HOSTNAME=$target_hostname/g" /etc/sysconfig/network-scripts/ifcfg-eth0
    systemctl restart NetworkManager
  fi
}
