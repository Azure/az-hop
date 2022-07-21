#!/bin/bash

NVME_DISKS_NAME=`ls /dev/nvme*n1`
NVME_DISKS=`ls -latr /dev/nvme*n1 | wc -l`

echo "Number of NVMe Disks: $NVME_DISKS"

if [ "$NVME_DISKS" == "0" ]
then
    exit 0
else
    mkdir -p /mnt/nvme
    # Needed incase something did not unmount as expected. This will delete any data that may be left behind
    mdadm  --stop /dev/md*
    mdadm --create /dev/md128 -f --run --level 0 --raid-devices $NVME_DISKS $NVME_DISKS_NAME
    mkfs.xfs -f /dev/md128
    mount /dev/md128 /mnt/nvme || exit 1
fi

chmod 1777 /mnt/nvme
