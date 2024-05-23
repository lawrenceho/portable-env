# Prefer latest release image and latest packages
# hadolint global ignore=DL3007,DL3041

FROM fedora:latest

ARG USER

ENV DOCKER_TLS_CERTDIR=/certs

COPY --from=docker:dind /usr/local/bin /usr/local/bin
COPY --from=docker:dind \
     /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins
COPY *.sh /usr/local/bin

# dnsmasq would provide name resolution service for containers
# using the default bridge network

# /var/run/utmp is touched as it is not in the image
# sshd would print an error message related to logout if utmp is missing

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN sed -i 's/tsflags/#tsflags/' /etc/dnf/dnf.conf && \
    printf 'install_weak_deps=False\n' >> /etc/dnf/dnf.conf && \
    sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/fedora-cisco-openh264.repo && \
    /usr/local/bin/image-preinstall.sh && \
    dnf -y reinstall $(dnf list --installed | tail -n +2 | awk -F '.' '{print $1}') && \
    dnf -y upgrade && \
    dnf -y install \
        bash-completion \
        dnsmasq \
        file \
        gcc \
        git \
        hostname \
        iproute \
        iptables-nft \
        java-17-openjdk-devel \
        java-17-openjdk-src \
        keychain \
        kmod \
        make \
        man-db \
        man-pages \
        neovim \
        npm \
        openssh-clients \
        openssh-server \
        openssl \
        procps \
        ripgrep \
        tmux \
        unzip \
        which && \
    touch /var/run/utmp && \
    ssh-keygen -A && \
    curl -sSo /etc/bash_completion.d/docker.sh \
        https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker && \
    groupadd -g 2375 -r docker && \
    mkdir /certs /certs/client && \
    chmod 1777 /certs /certs/client && \
    printf '%%wheel ALL=(ALL) NOPASSWD:ALL\n' >> /etc/sudoers && \
    useradd -M -G wheel,docker ${USER} && \
    mkdir /home/${USER} && \
    chown ${USER}:${USER} /home/${USER} && \
    /usr/local/bin/image-postinstall.sh && \
    rm /usr/local/bin/image-preinstall.sh /usr/local/bin/image-postinstall.sh && \
    dnf clean all

VOLUME /var/lib/docker

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
