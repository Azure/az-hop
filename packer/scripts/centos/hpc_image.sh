#!/bin/bash
set -e
yum install -y git

chmod 777 /mnt/resource
cd /mnt/resource

git clone https://github.com/Azure/azhpc-images -b centos-hpc-20220112

# Fix to allow NVIDIA drivers to be installed
#yum install -y https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/d/dkms-3.0.5-1.el7.noarch.rpm
#sed -i 's/6d88af6382fa3013e158b60128ef1fb117f4a4cc0fb6225155a2f7ff1c4a147f/ade1051a189fe84a326b8021d1446eb03d48e0a998e8cada85081b27a89923f1/g' ./azhpc-images/centos/centos-7.x/common/install_nvidiagpudriver.sh
#sed -i 's/4bf0cccc4764f59b69e1df3b104ba8ecb77dc4bd98264b89d20aabd290808100/586bf03a7b0c9827c80dc0a82c6e8fe780ff1d76d82b103866906e4cdd191710/g' ./azhpc-images/centos/centos-7.x/common/install_dcgm.sh

cd ./azhpc-images/centos/centos-7.x/centos-7.9-hpc
cat << EOF >>./install_nogpu.sh
#!/bin/bash
set -ex

# set properties
source ./set_properties.sh

# install utils
./install_utils.sh

# install compilers
./install_gcc.sh

# install mellanox ofed
./install_mellanoxofed.sh

# install mpi libraries
./install_mpis.sh

# cleanup downloaded tarballs
rm -rf *.tgz *.bz2 *.tbz *.tar.gz
rm -rf -- */

# install nvidia gpu driver
#./install_nvidiagpudriver.sh

# install AMD tuned libraries
./install_amd_libs.sh

# install Intel libraries
./install_intel_libs.sh

# Install NCCL
#./install_nccl.sh

# Install NVIDIA docker container
#\$COMMON_DIR/../centos/centos-7.x/common/install_docker.sh

# cleanup downloaded tarballs
rm -rf *.tar.gz *_offline.sh *.rpm *.run

# Install DCGM
#./install_dcgm.sh

# optimizations
./hpc-tuning.sh

# Network Optimization
#\$COMMON_DIR/network-tuning.sh

# install persistent rdma naming
\$COMMON_DIR/install_azure_persistent_rdma_naming.sh

# add udev rule
\$COMMON_DIR/../centos/common/add-udev-rules.sh

# add interface rules
\$COMMON_DIR/../centos/common/network-config.sh

# install diagnostic script
\$COMMON_DIR/install_hpcdiag.sh

# copy test file
\$COMMON_DIR/copy_test_file.sh

# disable cloud-init
./disable_cloudinit.sh

# clear history
# Uncomment the line below if you are running this on a VM
./clear_history.sh

EOF

chmod +x ./install_nogpu.sh
./install_nogpu.sh

#./install.sh
#cd /mnt/resource/azhpc-images/tests/run-tests.sh --mofed-lts false
