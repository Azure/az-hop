#!/bin/bash
set -euox pipefail

CS_CLIENT_URL=https://dvpublicsa.blob.core.windows.net/bits/lustre-cray-2.12.B51.g65b567.zip
CS_CLIENT_ZIP=lustre-cray-2.12.B51.g65b567.zip

# Install required OS components
yum groupinstall -y "Development Tools"
yum install -y kernel-devel-$(uname -r) zlib-devel libyaml-devel pdsh

# Build and install Cray Lustre client RPM packages
cd /tmp
wget $CS_CLIENT_URL
unzip $CS_CLIENT_ZIP
rpmbuild --rebuild --without servers --without lustre-tests --define 'configure_args --with-o2ib=no' lustre-*.src.rpm
yum install -y /root/rpmbuild/RPMS/x86_64/{kmod-lustre-client,lustre-client}-2.12.4.4*.x86_64.rpm
