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
    dnf install -y epel-release
    dnf install -y https://github.com/Azure/cyclecloud-pbspro/releases/download/${cyclecloud_pbspro}/openpbs-execution-${openpbs_version}-0.x86_64.rpm jq
}

function build19() {
    [ -d /opt/pbs ] && exit 0

    dnf install -y gcc make rpm-build libtool hwloc-devel \
        libX11-devel libXt-devel libedit-devel libical-devel \
        ncurses-devel perl postgresql-devel postgresql-contrib python2 python2-devel tcl-devel \
        tk-devel swig expat-devel openssl-devel libXext libXft \
        autoconf automake gcc-c++ git jq

    cd /mnt
    rm -rf hwloc
    git clone https://github.com/open-mpi/hwloc.git -b v1.11
    cd hwloc
    ./autogen.sh
    ./configure --enable-static --enable-embedded-mode
    make
    cd ..

    wget -q https://github.com/openpbs/openpbs/releases/download/v19.1.1/pbspro-19.1.1.tar.gz -O pbspro-19.1.1.tar.gz
    tar -xzf pbspro-19.1.1.tar.gz
    cd pbspro-19.1.1/
    ./configure --prefix=/opt/pbs PYTHON=/usr/bin/python2.7 CFLAGS="-I$PWD/../hwloc/include" LDFLAGS="-L$PWD/../src"
    make
    make install

    /opt/pbs/libexec/pbs_postinstall execution
    chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
}


# If PBS is not installed, then install it
if [ ! -f "/etc/pbs.conf" ]; then
    install_or_build $major_wanted_pbs_version
else
    # If installed version is not the same as the version we want to install, then remove and install it
    if [ "$major_installed_pbs_version" != "major_wanted_pbs_version" ]; then
        echo "Removing old PBS version $major_installed_pbs_version"
        set +e
        systemctl stop pbs
        rm -rf /opt/pbs
        rm -rf /var/spool/pbs
        set -e
        install_or_build $major_wanted_pbs_version
    fi
fi