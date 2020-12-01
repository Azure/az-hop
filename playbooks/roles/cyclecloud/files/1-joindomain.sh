#!/bin/bash

yum install sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y

systemctl restart dbus
systemctl restart systemd-logind

NAMESERVER=$(jetpack config adjoin.ad_server)

echo "supersede domain-name-servers ${NAMESERVER};" > /etc/dhcp/dhclient.conf
echo "append domain-name-servers 168.63.129.16;" >> /etc/dhcp/dhclient.conf
systemctl restart NetworkManager

sleep 10

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

cat <<EOF >/etc/ssh/ssh_config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

ADMIN_DOMAIN=$(jetpack config adjoin.ad_domain)
ADMIN_NAME=$(jetpack config adjoin.ad_admin)
ADMIN_PASSWORD=$(jetpack config adjoin.ad_password)

echo $ADMIN_PASSWORD| realm join -U $ADMIN_NAME $ADMIN_DOMAIN

sed -i 's@use_fully_qualified_names.*@use_fully_qualified_names = False@' /etc/sssd/sssd.conf
sed -i 's@ldap_id_mapping.*@ldap_id_mapping = False@' /etc/sssd/sssd.conf

systemctl restart sssd
