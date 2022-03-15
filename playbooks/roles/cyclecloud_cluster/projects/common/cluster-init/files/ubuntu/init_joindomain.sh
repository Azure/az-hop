#!/bin/bash
ad_dns=$1
ldap_server=$2
ad_join_domain=$3

packages="sssd libsss-simpleifp0 sssd-dbus sssd-tools realmd oddjob oddjob-mkhomedir adcli samba-common krb5-user ldap-utils packagekit resolvconf"

if [ "$os_maj_ver" == "18.04" ]; then
    packages="$packages python-sss"
fi

if ! dpkg -l $packages ; then
  apt -y update
  echo "Installing packages $packages" 
  # this export is needed to stop input for krb5-user
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y $packages
  echo "Restart dbus"
  # Manually restarting dbus is blocked on ubuntu
  # systemctl restart dbus
  echo "Restart systemd-logind"
  systemctl restart systemd-logind
fi

# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/azure-dns
if grep "^options " /etc/resolv.conf; then
  sed -i 's/^options /options timeout:1 attempts:5 /' /etc/resolv.conf
else
  echo "options timeout:1 attempts:5" >> /etc/resolv.conf
fi

# needed for ubuntu
if ! grep "$ad_dns" /etc/hosts; then
  echo "$ad_dns $ldap_server.$ad_join_domain $ldap_server" >> /etc/hosts
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

  if ! systemctl restart systemd-networkd; then
    logger -s "failed to restart systemd-networkd"
  fi
}
