#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/../files/azhop-helpers.sh" 
read_os

$script_dir/../files/$os_release/cvmfs-eessi.sh
