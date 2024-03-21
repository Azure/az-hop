#!/bin/bash
cyclecloud_pbspro=$1
openpbs_version=$2

major_installed_pbs_version=$(cat /var/spool/pbs/pbs_version | cut -d '=' -f2 | cut -d '.' -f1)
major_wanted_pbs_version=$(echo $openpbs_version | cut -d '.' -f1)

function install_or_build() {
    local version=$1
    case $version in
        19)
            build19
            ;;
        20|22)
            install
            ;;
        *)
            echo "Unsupported PBS version: $version"
            exit 1
            ;;
    esac
}

function install() {
    cd /mnt
    wget -q https://vcdn.altair.com/rl/OpenPBS/openpbs_${openpbs_version}.ubuntu_20.04.zip
    unzip openpbs_${openpbs_version}.ubuntu_20.04.zip
    apt-get install -y ./openpbs_${openpbs_version}.ubuntu_20.04/openpbs-execution_${openpbs_version}-1_amd64.deb
}

function build19() {
    [ -d /opt/pbs ] && exit 0

    cd /mnt
    wget -q https://github.com/openpbs/openpbs/releases/download/v19.1.1/pbspro-19.1.1.tar.gz -O pbspro-19.1.1.tar.gz
    tar -xzf pbspro-19.1.1.tar.gz
    cd pbspro-19.1.1/

    apt-get install -y gcc make libtool libhwloc-dev libx11-dev libxt-dev libedit-dev libical-dev ncurses-dev perl postgresql-server-dev-all postgresql-contrib python-dev tcl-dev tk-dev swig libexpat-dev libssl-dev libxext-dev libxft-dev autoconf automake
    ./autogen.sh
    ./configure --prefix=/opt/pbs PYTHON=/usr/bin/python2.7
    make
    make install

    /opt/pbs/libexec/pbs_postinstall execution
    chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
}

install_or_build $major_wanted_pbs_version

# # If PBS is not installed, then install it
# if [ ! -f "/etc/pbs.conf" ]; then
#     install_or_build $major_wanted_pbs_version
# else
#     # If installed version is not the same as the version we want to install, then remove and install it
#     if [ "$major_installed_pbs_version" != "major_wanted_pbs_version" ]; then
#         echo "Removing old PBS version $major_installed_pbs_version"
#         set +e
#         systemctl stop pbs
#         rm -rf /opt/pbs
#         rm -rf /var/spool/pbs
#         set -e
#         install_or_build $major_wanted_pbs_version
#     fi
# fi


