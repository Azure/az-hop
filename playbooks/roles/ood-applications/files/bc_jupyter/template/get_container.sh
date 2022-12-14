#!/usr/bin/env bash
set -e
echo "Getting container..."
echo "TTT - $(date)"
container_image=$1
container_name=$2

echo "container_image=$container_image"
echo "container_name=$container_name"
# add the default docker:// if no prefix is provided
if [ "$container_image" != *"://"* ]; then
    container_image="docker://$container_image"
    echo "container_image=$container_image"
fi

echo "enroot import"
# remove any prefix :// and replace chars in (/:) by +
container_squashfs_path=${container_image#*://}
container_squashfs_path=${container_squashfs_path//\//+}
container_squashfs_path=${container_squashfs_path//:/+}

# get the enroot temp path to store squashfs files
ENROOT_TEMP_PATH=$(grep ENROOT_TEMP_PATH /etc/enroot/enroot.conf | cut -d' ' -f2)
ENROOT_TEMP_PATH=${ENROOT_TEMP_PATH:-/tmp}
echo "ENROOT_TEMP_PATH=$ENROOT_TEMP_PATH"
container_squashfs_path="$ENROOT_TEMP_PATH/$container_squashfs_path.sqsh"
echo "container_squashfs_path=$container_squashfs_path"

# import the container and save the sqsh file in the enroot temporary path configured in /etc/enroot/enroot.conf
enroot import --output $container_squashfs_path $container_image

echo "enroot create container"
enroot create --name $container_name $container_squashfs_path

echo "remove squashfs file $container_squashfs_path"
rm -f $container_squashfs_path