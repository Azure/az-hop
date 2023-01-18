#!/bin/bash
lustre_version=${1-2.12.5}
lustre_dir="lustre-$lustre_version"

cat << EOF >/etc/yum.repos.d/LustrePack.repo
#[lustreserver]
#name=lustreserver
#baseurl=https://downloads.whamcloud.com/public/lustre/${lustre_dir}/el8/patchless-ldiskfs-server/
#enabled=0
#gpgcheck=0

[e2fs]
name=e2fs
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/latest/el8/
enabled=1
gpgcheck=0

[lustreclient]
name=lustreclient
baseurl=https://downloads.whamcloud.com/public/lustre/${lustre_dir}/el8/client/
enabled=1
gpgcheck=0
EOF

dnf -y install kmod-lustre-client lustre-client || exit 1
weak-modules --add-kernel $(uname -r) || exit 1
