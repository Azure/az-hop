#!/bin/bash
set -e
# Installs Ansible. Optionally in a conda environment.
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MINICONDA_URL_LINUX_X86="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_URL_LINUX_ARM="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
MINICONDA_URL_MAC_X86="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
MINICONDA_URL_MAC_ARM="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
MINICONDA_INSTALL_DIR=${1:-miniconda}
MINICONDA_INSTALL_SCRIPT="miniconda-installer.sh"

# Always use of virtual environment
INSTALL_IN_CONDA=${INSTALL_IN_CONDA:-true}
if [ $INSTALL_IN_CONDA = true ]; then
    os_type=$(uname | awk '{print tolower($0)}')
    os_arch=$(arch)
    if [[ "$os_type" == "darwin" ]]; then
        if [[ "$os_arch" == "arm64" ]]; then
            miniconda_url=$MINICONDA_URL_MAC_ARM
        else
            miniconda_url=$MINICONDA_URL_MAC_X86
        fi
    elif [[ "$os_type" == "linux" ]]; then
        if [[ "$os_arch" == "aarch64" ]]; then
            miniconda_url=$MINICONDA_URL_LINUX_ARM
        else
            miniconda_url=$MINICONDA_URL_LINUX_X86
        fi
    else
        printf "Unsupported OS"
        exit 1
    fi

    # Reuse environment if it doesn't already exist
    if [[ ! -d "${MINICONDA_INSTALL_DIR}" ]]; then
        printf "Installing Ansible in conda environment in %s from %s \n\n" "${MINICONDA_INSTALL_DIR}" "${miniconda_url}"

        # Actually install environment and install in base environment
        if [[ ! -f ${MINICONDA_INSTALL_SCRIPT} ]]; then
            wget $miniconda_url -O $MINICONDA_INSTALL_SCRIPT
        fi
        bash $MINICONDA_INSTALL_SCRIPT -b -p $MINICONDA_INSTALL_DIR
        source "${MINICONDA_INSTALL_DIR}/bin/activate"
    else
        printf "Installing Ansible in existing conda environment in %s \n\n" "${MINICONDA_INSTALL_DIR}"
        source "${MINICONDA_INSTALL_DIR}/bin/activate"
    fi

    printf "Update packages\n"
    conda update -y --all
else
    printf "Attempting to install Ansible in base environment\n"
    printf "If this fails, please run this script with the --conda flag\n\n"
fi

# Install Ansible
printf "Installing Ansible\n"
python3 -m pip install -r ${THIS_DIR}/requirements.txt

# Install Ansible collections
printf "Installing Ansible collections\n"
ansible-galaxy collection install -r ${THIS_DIR}/requirements.yml

# Install azhop dependencies
printf "Installing Az-hop dependencies\n"
ansible-playbook ${THIS_DIR}/azhop-dependencies.yml

printf "\n\n"
printf "Applications installed\n"
printf "===============================================================================\n"
columns="%-16s| %.10s\n"
printf "$columns" Application Version
printf -- "-------------------------------------------------------------------------------\n"
printf "$columns" Python `python3 --version | awk '{ print $2 }'`
printf "$columns" Ansible `ansible --version | head -n 1 | awk '{ print $3 }' | sed 's/]//'`
printf "$columns" Terraform `terraform --version | head -n 1 | awk '{ print $2 }' | sed 's/v//'`
printf "$columns" Packer `/usr/bin/packer --version | awk '{ print $2 }'`
printf "$columns" az-cli `az --version 2> /dev/null | head -n 1 | awk '{ print $2 }'`
printf "$columns" azcopy `azcopy --version | head -n 1 | awk '{ print $3 }'`
printf "$columns" yq `yq --version | awk '{ print $4 }'`
printf "$columns" check-jsonschema `check-jsonschema --version | awk '{ print $3 }'`
printf "===============================================================================\n"

if [ $INSTALL_IN_CONDA = true ]; then
    yellow=$'\e[1;33m'
    default=$'\e[0m'
    printf "\n${yellow}Az-HOP dependencies installed in a conda environment${default}. To activate, run:\n"
    printf "\nsource %s/bin/activate\n\n" "${MINICONDA_INSTALL_DIR}"
fi
