#!/bin/bash
CUDA_REPO_PKG=cuda-repo-rhel7-10.0.130-1.x86_64.rpm
wget http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/${CUDA_REPO_PKG} -O /tmp/${CUDA_REPO_PKG}
sudo rpm -ivh /tmp/${CUDA_REPO_PKG}
rm -f /tmp/${CUDA_REPO_PKG}
sudo yum -y install cuda-drivers
