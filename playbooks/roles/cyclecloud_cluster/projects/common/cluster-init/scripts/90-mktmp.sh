#!/bin/bash
# written by Jeff Jones. Slight modifications by Matt Chan

if [ ! -e /etc/redhat-release]; then
  exit 0
fi

echo "Resetting /mnt/resource/tmpscratch and /tmp/scratch"
rm -rf /mnt/resource/tmpscratch
rm -rf /mnt/nvme/tmpscratch
rm -rf /tmp/scratch
rm -rf /mnt/scratch
if [ -d /mnt/nvme ]; then
    chmod -R 1777 /mnt/nvme
    mkdir /mnt/nvme/tmpscratch
    chmod -R 1777 /mnt/nvme/tmpscratch
#    touch /mnt/nvme/tmpscratch/PUT_YOUR_USER_SCRATCH_FOLDERS_HERE
    ln -s /mnt/nvme/tmpscratch /tmp/scratch
    ln -s /mnt/nvme/tmpscratch /mnt/scratch
elif [ -d /mnt/resource ]; then
    chmod -R 1777 /mnt/resource
    mkdir /mnt/resource/tmpscratch
    chmod -R 1777 /mnt/resource/tmpscratch
#    touch /mnt/resource/tmpscratch/PUT_YOUR_USER_SCRATCH_FOLDERS_HERE
    ln -s /mnt/resource/tmpscratch /tmp/scratch
    ln -s /mnt/resource/tmpscratch /mnt/scratch
else
    echo "/mnt/resource nor /mnt/nvme does not exist!"
    exit 1
fi
echo "Cleanup complete."
