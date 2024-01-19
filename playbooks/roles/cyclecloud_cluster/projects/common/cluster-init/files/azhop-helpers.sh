#!/bin/bash
# Library of functions to be used across scripts
read_os()
{
    os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | xargs)
    os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | xargs)
    full_version=$(cat /etc/os-release | grep "^VERSION\=" | cut -d'=' -f 2 | xargs)
}

is_centos()
{
    read_os
    if [ "$os_release" == "centos" ]; then
        return 0
    else
        return 1
    fi
}

is_centos8()
{
    read_os
    if [ "$os_release" == "centos" ] && [ "$os_maj_ver" == "8" ]; then
        return 0
    else
        return 1
    fi
}

is_centos7()
{
    read_os
    if [ "$os_release" == "centos" ] && [ "$os_maj_ver" == "7" ]; then
        return 0
    else
        return 1
    fi
}

is_ubuntu()
{
    read_os
    if [ "$os_release" == "ubuntu" ]; then
        return 0
    else
        return 1
    fi
}

retry_command() {
    local cmd=$1
    local retries=${2:-5}
    local delay=${3:-10}

    set +eo pipefail

    for ((i=0; i<retries; i++)); do
        echo "Running command: $cmd"
        $cmd

        if [ $? -eq 0 ]; then
            echo "Command succeeded!"
            set -eo pipefail
            return 0
        else
            echo "Command failed. Retrying in ${delay}s..."
            sleep $delay
        fi
    done

    echo "Command failed after $retries retries."
    set -eo pipefail
    return 1
}
