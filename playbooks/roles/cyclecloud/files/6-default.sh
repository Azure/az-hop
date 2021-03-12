#!/bin/bash
# Apply default configuration to the node

# change access to resource so that temp jobs can be written there
chmod 777 /mnt/resource

# Grant domain users sudo with no password
echo "\"%domain users\" ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers