#!/usr/bin/env bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Starting enroot wrapper..."
echo "TTT - $(date)"
container_name=$1

echo "container_name=$container_name"
echo "enroot start"
enroot start --rw -e NOTEBOOK_ROOT="$NOTEBOOK_ROOT" -e CONFIG_FILE="$CONFIG_FILE" -e port="$port" $container_name $THIS_DIR/start_rstudio.sh
echo "enroot remove"
enroot remove -f $container_name
