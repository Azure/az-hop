#!/usr/bin/env bash
echo "Getting container..."
echo "TTT - $(date)"
container_image=$1
container_name=$2

# TODO: add docker:// if no prefix is provided
enroot import docker://$container_image

# replace [/:] by +
container_image=${container_image//\//+}
container_image=${container_image//:/+}

# TODO : place the sqsh file in the enroot temporary configured
enroot create --name $container_name $container_image.sqsh

# TODO: remove sqsh file