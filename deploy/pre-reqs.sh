#!/bin/bash
set -e

#
# Install yq
#
echo "Installing yq...."
VERSION=v4.25.3
BINARY=yq_linux_amd64
wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O ${HOME}/bin/yq && chmod +x ${HOME}/bin/yq
