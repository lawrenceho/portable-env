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
  containerd.io \
  dnsmasq \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  fd-find \
  file \
  fzf \
  gcc \
  git \
  hostname \
  iproute \
  libicu \
  make \
  man-db \
  man-pages \
  mise \
  neovim \
  nodejs-full-i18n \
  nodejs-npm \
  novnc \
  openssh-clients \
  openssh-server \
  openssl \
  pass \
  pinentry \
  procps \
  python3 \
  restic \
  ripgrep \
  systemd \
  temurin-21-jdk \
  tigervnc-server \
  tree-sitter-cli \
  tmux \
  unzip \
  @xfce-desktop-environment

# Disable getty
systemctl disable getty@tty1

# SSH
systemctl enable sshd

# Docker
systemctl enable docker
curl -sSo /etc/bash_completion.d/docker.sh \
  https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker

# dnsmasq
mkdir -p /etc/systemd/system/dnsmasq.service.d
printf '[Unit]\nBefore=\nAfter=docker.service\nWants=docker.service\n[Service]\nExecStartPre=/usr/local/bin/dnsmasq-execstartpre.sh\nExecStartPost=/usr/local/bin/dnsmasq-execstartpost.sh\n' \
  >>/etc/systemd/system/dnsmasq.service.d/dnsmasq.conf
systemctl enable dnsmasq

# TigerVNC
printf ":0=${USER}\n" >>/etc/tigervnc/vncserver.users
printf 'session=xfce\nsecuritytypes=none\n' >>/etc/tigervnc/vncserver-config-defaults
systemctl enable vncserver@:0

# Disable unused services
systemctl disable abrtd
systemctl disable atd
systemctl disable avahi-daemon
systemctl disable avahi-daemon.socket
systemctl disable chronyd
systemctl disable crond
systemctl disable firewalld
systemctl disable lightdm
systemctl disable rsyslog
systemctl disable rtkit-daemon
systemctl disable systemd-resolved
systemctl disable systemd-userdbd.socket
systemctl disable upower
systemctl disable udisks2
systemctl disable NetworkManager
systemctl mask accounts-daemon
systemctl mask gssproxy
systemctl mask polkit
systemctl mask systemd-udevd-control.socket
systemctl mask systemd-udevd-kernel.socket
systemctl mask systemd-udevd

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
