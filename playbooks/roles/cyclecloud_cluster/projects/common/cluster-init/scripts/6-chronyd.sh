#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/../files/azhop-helpers.sh" 
read_os

# Only CentOS needs to configure chronyd
$script_dir/../files/$os_release/init_chronyd.sh
