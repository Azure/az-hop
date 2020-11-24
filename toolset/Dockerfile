FROM ubuntu:18.04

# Arguments set during docker-compose build -b --build from .env file

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG SSH_PASSWD

ENV SSH_PASSWD=${SSH_PASSWD} \
    USERNAME=${USERNAME} \
    TF_DATA_DIR="/home/${USERNAME}/.terraform.cache" \
    TF_PLUGIN_CACHE_DIR="/home/${USERNAME}/.terraform.cache/plugin-cache" \
    DEBIAN_FRONTEND=noninteractive

RUN \
    # To make it easier for build and release pipelines to run apt-get,
    # configure apt to not require confirmation (assume the -y argument by default)
    echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes && \
    apt-get update && \
    # Install basic command-line utilities
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        file \
        ftp \
        gettext-base \
        git \
        iproute2 \
        iputils-ping \
        jq \
        libcurl4 \
        libicu60 \
        libunwind8 \
        locales \
        netcat \
        openssh-client \
        parallel \
        rsync \
        shellcheck \
        sudo \
        telnet \
        time \
        unzip \
        upx \
        wget \
        zip \
        tzdata && \
        # install python packages
        apt-get install python3-pip && \
        # pip3 install pypsrp && \
        # pip3 install pysocks && \
        # Install AzCLI
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
        # Install Ansible
        apt update -y && \
        apt install -y software-properties-common && \
        apt-add-repository --yes --update ppa:ansible/ansible && \
        apt install -y ansible && \
        #
        # Create USERNAME
        #
        echo "Creating ${USERNAME} user..." && \
        #useradd --uid $USER_UID -m -G docker ${USERNAME} && \ # Group docker does'nt exists
        useradd --uid $USER_UID -m ${USERNAME} && \
        #
        # Install Terraform
        #
        echo "Installing terraform ..." && \
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && \
        sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
        sudo apt-get update && sudo apt-get install terraform && \
        mkdir -p /home/${USERNAME}/.terraform.cache/plugin-cache && \
        # Clean-up
        rm -f /tmp/*.zip && rm -f /tmp/*.gz && \
        #
        # Create USERNAME home folder structure
        #
        mkdir -p  /hpc/scripts \
            /home/${USERNAME}/.ansible \
            /home/${USERNAME}/.azure \
            /home/${USERNAME}/.ssh \
            /home/${USERNAME}/.ssh-localhost \
            /home/${USERNAME}/.terraform.cache \
            /home/${USERNAME}/.terraform.cache/tfstates \
            /home/${USERNAME}/.vscode-server \
            /home/${USERNAME}/.vscode-server-insiders && \
        chown -R ${USER_UID}:${USER_GID} /home/${USERNAME} /hpc/scripts && \
        chmod 777 -R /home/${USERNAME} && \
        chmod 700 /home/${USERNAME}/.ssh && \
        echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
        chmod 0440 /etc/sudoers.d/${USERNAME} && \
        # setting up keys
        echo "Host *" > /home/${USERNAME}/.ssh/config && \
        echo "    StrictHostKeyChecking no" >> /home/${USERNAME}/.ssh/config && \
        echo "    UserKnownHostsFile /dev/null" >> /home/${USERNAME}/.ssh/config && \
        echo "    LogLevel ERROR" >> /home/${USERNAME}/.ssh/config && \
        chmod 644 /home/${USERNAME}/.ssh/config

WORKDIR /hpc/scripts
COPY ./scripts/sshd.sh .

#
# Switch to ${USERNAME} context
#

USER ${USERNAME}

COPY ./scripts/sshd_config /home/${USERNAME}/.ssh/sshd_config

# ssh server for Azure ACI
RUN    ssh-keygen -q -N "" -t ecdsa -b 521 -f /home/${USERNAME}/.ssh/ssh_host_ecdsa_key && \ 
#         ansible-galaxy collection install ansible.windows && \
#         ansible-galaxy collection install community.windows && \

EXPOSE 22
CMD  ["/hpc/scripts/sshd.sh"]