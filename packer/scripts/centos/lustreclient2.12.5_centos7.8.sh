#!/bin/bash

lustre_dir=lustre-2.12.5

cat << EOF >/etc/yum.repos.d/LustrePack.repo
[lustreserver]
name=lustreserver
baseurl=https://downloads.whamcloud.com/public/lustre/${lustre_dir}/el7/patchless-ldiskfs-server/
enabled=1
gpgcheck=1

[e2fs]
name=e2fs
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/latest/el7/
enabled=1
gpgcheck=1

[lustreclient]
name=lustreclient
baseurl=https://downloads.whamcloud.com/public/lustre/${lustre_dir}/el7/client/
enabled=1
gpgcheck=1
EOF

yum -y install lustre-client
weak-modules --add-kernel $(uname -r)
