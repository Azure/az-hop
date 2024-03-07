#!/bin/bash
set -e
# Update packages 
apt-get clean
apt-get update #&& apt-get upgrade -y
#yum update -y --exclude kernel*, kmod*

# Install git using ubuntu 
apt-get install -y git 

#mkdir /mnt/resource 
#chmod 777 /mnt/resource
cd /mnt/

git clone https://github.com/Azure/azhpc-images -b ubuntu-hpc-20231127

# Fix to allow NVIDIA drivers to be installed
#yum install -y https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/d/dkms-3.0.5-1.el7.noarch.rpm
#sed -i 's/6d88af6382fa3013e158b60128ef1fb117f4a4cc0fb6225155a2f7ff1c4a147f/ade1051a189fe84a326b8021d1446eb03d48e0a998e8cada85081b27a89923f1/g' ./azhpc-images/centos/centos-7.x/common/install_nvidiagpudriver.sh
#sed -i 's/4bf0cccc4764f59b69e1df3b104ba8ecb77dc4bd98264b89d20aabd290808100/586bf03a7b0c9827c80dc0a82c6e8fe780ff1d76d82b103866906e4cdd191710/g' ./azhpc-images/centos/centos-7.x/common/install_dcgm.sh

cd ./azhpc-images/ubuntu/ubuntu-20.x/ubuntu-20.04-hpc
cat << EOF >>./install_nogpu.sh

#!/bin/bash
set -ex

# set properties
source ./set_properties.sh

# install utils
./install_utils.sh

source ./set_properties.sh
# install Lustre client
\$UBUNTU_COMMON_DIR/install_lustre_client.sh

# install mellanox ofed
./install_mellanoxofed.sh

# install mpi libraries
./install_mpis.sh

# install nvidia gpu driver
#./install_nvidiagpudriver.sh

# Install NCCL
# $UBUNTU_COMMON_DIR/install_nccl.sh

# Install NVIDIA docker container
# $UBUNTU_COMMON_DIR/install_docker.sh

# cleanup downloaded tarballs - clear some space
rm -rf *.tgz *.bz2 *.tbz *.tar.gz *.run *.deb *_offline.sh
rm -rf /tmp/MLNX_OFED_LINUX* /tmp/*conf*
rm -rf /var/intel/ /var/cache/*
rm -Rf -- */

# Install DCGM
#$UBUNTU_COMMON_DIR/install_dcgm.sh

# install Intel libraries
\$UBUNTU_COMMON_DIR/install_intel_libs.sh

# install diagnostic script
\$COMMON_DIR/install_hpcdiag.sh

# install persistent rdma naming
\$COMMON_DIR/install_azure_persistent_rdma_naming.sh

# optimizations
\$UBUNTU_COMMON_DIR/hpc-tuning.sh

# copy test file
\$COMMON_DIR/copy_test_file.sh

# install monitor tools
\$UBUNTU_COMMON_DIR/install_monitoring_tools.sh

# install AMD libs
\$UBUNTU_COMMON_DIR/install_amd_libs.sh

# install Azure/NHC Health Checks
\$COMMON_DIR/install_health_checks.sh

# diable auto kernel updates
\$UBUNTU_COMMON_DIR/disable_auto_upgrade.sh

# Disable Predictive Network interface renaming
\$UBUNTU_COMMON_DIR/disable_predictive_interface_renaming.sh

# SKU Customization
\$COMMON_DIR/setup_sku_customizations.sh

# clear history
# Uncomment the line below if you are running this on a VM
# $COMMON_DIR/clear_history.sh

EOF

chmod +x ./install_nogpu.sh
./install_nogpu.sh

#./install.sh
#cd /mnt/resource/azhpc-images/tests/run-tests.sh --mofed-lts false
