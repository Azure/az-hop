FROM ubuntu:22.04

# Arguments set during docker-compose build -b --build from .env file

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG SSH_PASSWD

ENV SSH_PASSWD=${SSH_PASSWD} \
    USERNAME=${USERNAME} \
    # TF_DATA_DIR="/home/${USERNAME}/.terraform.cache" \
    # TF_PLUGIN_CACHE_DIR="/home/${USERNAME}/.terraform.cache/plugin-cache" \
    DEBIAN_FRONTEND=noninteractive

COPY ./scripts/* /tmp/

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes && \
    apt-get update && \
    apt install -y wget openssh-client sudo && \
    chmod +x /tmp/install.sh && \
    /tmp/install.sh && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get full-upgrade -y && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
#
    echo "Creating ${USERNAME} user..." && \
    useradd --uid $USER_UID -m ${USERNAME} && \
#
# Create USERNAME home folder structure
#
    mkdir -p  /hpc/scripts \
        /home/${USERNAME}/.ansible \
        /home/${USERNAME}/.azure \
        /home/${USERNAME}/.ssh \
        /home/${USERNAME}/.ssh-localhost \
        /home/${USERNAME}/.terraform.cache \
        /home/${USERNAME}/.terraform.cache/plugin-cache \
        /home/${USERNAME}/.terraform.cache/tfstates \
        /home/${USERNAME}/.vscode-server \
        /home/${USERNAME}/.vscode-server-insiders \
        /etc/sudoers.d && \
    chown -R ${USER_UID}:${USER_GID} /home/${USERNAME} /hpc/scripts && \
    chmod 777 -R /home/${USERNAME} && \
    chmod 700 /home/${USERNAME}/.ssh && \
    echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

WORKDIR /hpc/scripts
COPY ./scripts/sshd.sh .

#
# Switch to ${USERNAME} context
#
USER ${USERNAME}

COPY ./scripts/sshd_config /home/${USERNAME}/.ssh/sshd_config
COPY ./scripts/ssh_config /home/${USERNAME}/.ssh/config

# ssh server for Azure ACI
RUN ssh-keygen -q -N "" -t ecdsa -b 521 -f /home/${USERNAME}/.ssh/ssh_host_ecdsa_key && \
    sudo chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh/config && \
    sudo chmod 644 /home/${USERNAME}/.ssh/config

EXPOSE 22
CMD  ["/hpc/scripts/sshd.sh"]
