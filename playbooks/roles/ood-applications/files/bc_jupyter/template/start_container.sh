#!/usr/bin/env bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Starting enroot wrapper..."
echo "TTT - $(date)"
container_name=$1

# check if another argument was passed
if [ $# -gt 1 ]; then
    shift
    CONTAINER_MOUNTS="$@"
else
    CONTAINER_MOUNTS=""
fi

# if countainer mounts is not empty, build a mount string 
# for example: given CONTAINER_MOUNTS="SRC:DST[,SRC:DST...]"
# create a string like "-m SRC:DST -m SRC2:DST2"
if [ -n "$CONTAINER_MOUNTS" ]; then
    MOUNT_STRING=$(echo "$CONTAINER_MOUNTS" | sed 's/,/ --mount /g' | sed 's/^/--mount /')
else
    MOUNT_STRING=""
fi


echo "container_name=$container_name"
echo "enroot start"
enroot start --rw $MOUNT_STRING -e NOTEBOOK_ROOT="$NOTEBOOK_ROOT" -e CONFIG_FILE="$CONFIG_FILE" $container_name $THIS_DIR/start_jupyter.sh
echo "enroot remove"
enroot remove -f $container_name
