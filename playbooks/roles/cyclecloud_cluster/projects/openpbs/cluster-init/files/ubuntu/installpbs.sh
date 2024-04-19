#!/bin/bash
cyclecloud_pbspro=$1
openpbs_version=$2

major_installed_pbs_version=$(cat /var/spool/pbs/pbs_version | cut -d '=' -f2 | cut -d '.' -f1)
major_wanted_pbs_version=$(echo $openpbs_version | cut -d '.' -f1)

cd /mnt
function install_version() {
    local version=$1
    case $version in
        22)
            install
            ;;
        *)
            echo "Unsupported PBS version: $version"
            exit 1
            ;;
    esac
}

function install() {
    apt install libpq5 -y
    wget -q https://vcdn.altair.com/rl/OpenPBS/openpbs_${openpbs_version}.ubuntu_20.04.zip
    unzip -o openpbs_${openpbs_version}.ubuntu_20.04.zip
    dpkg -i --force-overwrite --force-confnew ./openpbs_${openpbs_version}.ubuntu_20.04/openpbs-execution_${openpbs_version}-1_amd64.deb
    rm -rf openpbs_${openpbs_version}.ubuntu_20.04
    rm -f openpbs_${openpbs_version}.ubuntu_20.04.zip
}

install_version $major_wanted_pbs_version

