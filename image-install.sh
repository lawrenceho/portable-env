#!/bin/sh
set -eu

# https://github.com/koalaman/shellcheck/issues/2555
# shellcheck disable=SC3040
(set -o pipefail 2>/dev/null) && set -o pipefail

# Save script directory
DIR="$(dirname "$0")"

# Execute custom preinstall script
"$DIR"/image-preinstall.sh

# Disable unused repository
sed -i 's/enabled=1/enabled=0/' \
  /etc/yum.repos.d/fedora-cisco-openh264.repo \
  /etc/yum.repos.d/fedora-updates-testing.repo

# Disable installation of weak dependencies
printf 'install_weak_deps=False\n' >>/etc/dnf/dnf.conf

# Upgrade all installed packages
dnf -y upgrade

# Enable installation of documentation and reinstall all installed packages
sed -i 's/tsflags/#tsflags/' /etc/dnf/dnf.conf
# Word splitting is required
# shellcheck disable=SC2046
dnf -y reinstall $(dnf list --installed | tail -n +2 | cut -d '.' -f 1)

# Enable docker repository
dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo

# Install and enable adoptium temurin java repository
dnf -y install adoptium-temurin-java-repository
sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/adoptium-temurin-java-repository.repo

# Enable copr for mise
dnf -y copr enable jdxcode/mise

# dnsmasq is installed to provide name resolution service for containers
# using the default bridge network
# libicu is required for Marksman (but not used)
# https://github.com/artempyanykh/marksman/issues/209
# python3 is required for mason jdtls
dnf -y install \
  bash-completion \
  bubblewrap \
  containerd.io \
  dbus \
  dnsmasq \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  fd-find \
  file \
  fzf \
  gcc \
  gh \
  git \
  hostname \
  iproute \
  jq \
  libicu \
  make \
  man-db \
  man-pages \
  mise \
  neovim \
  openssh-clients \
  openssh-server \
  openssl \
  pass \
  pinentry \
  procps \
  python3 \
  restic \
  ripgrep \
  rustup \
  shellcheck \
  socat \
  systemd \
  systemd-pam \
  temurin-21-jdk \
  tree-sitter-cli \
  tmux \
  unzip \
  uv

# Disable getty
systemctl disable getty@tty1

# SSH
systemctl enable sshd

# Docker
systemctl enable docker
mkdir -p /etc/docker && printf '{"storage-driver": "overlay2"}\n' >>/etc/docker/daemon.json
curl -sSo /etc/bash_completion.d/docker.sh \
  https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker

# dnsmasq
mkdir -p /etc/systemd/system/dnsmasq.service.d
printf '[Unit]\nBefore=\nAfter=docker.service\nWants=docker.service\n[Service]\nExecStartPre=/usr/local/bin/dnsmasq-execstartpre.sh\nExecStartPost=/usr/local/bin/dnsmasq-execstartpost.sh\n' \
  >>/etc/systemd/system/dnsmasq.service.d/dnsmasq.conf
systemctl enable dnsmasq

# Create user
useradd -M -G docker "${USER}"
mkdir /home/"${USER}"
chown "${USER}":"${USER}" /home/"${USER}"

# Execute custom postinstall script
"$DIR"/image-postinstall.sh

# Clean up
dnf clean all
rm "$DIR"/image-install.sh \
  "$DIR"/image-preinstall.sh \
  "$DIR"/image-postinstall.sh
