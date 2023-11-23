#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/../files/azhop-helpers.sh"
read_os

if [ $os_maj_ver != '18.04' ]; then
  $script_dir/../files/$os_release/init_apptainer.sh
else
  exit 0
fi
