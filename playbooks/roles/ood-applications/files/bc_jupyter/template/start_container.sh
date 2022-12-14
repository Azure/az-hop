#!/usr/bin/env bash
echo "Starting enroot wrapper..."
echo "TTT - $(date)"
container_name=$1

enroot start --rw -e NOTEBOOK_ROOT="$NOTEBOOK_ROOT" -e CONFIG_FILE="$CONFIG_FILE" $container_name $THIS_DIR/start_jupyter.sh
enroot remove -f $container_name
