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
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/fedora-cisco-openh264.repo

# Disable installation of weak dependencies
printf 'install_weak_deps=False\n' >>/etc/dnf/dnf.conf

# Enable installation of documentation and reinstall all installed packages
sed -i 's/tsflags/#tsflags/' /etc/dnf/dnf.conf
# Word splitting is required
# shellcheck disable=SC2046
dnf -y reinstall $(dnf list --installed | tail -n +2 | awk -F '.' '{print $1}')

# Upgrade all installed packages
dnf -y upgrade

# dnsmasq is installed to provide name resolution service for containers
# using the default bridge network
dnf -y install \
  automake \
  bash-completion \
  bison \
  dnsmasq \
  fd-find \
  file \
  fuse \
  fzf \
  gcc \
  git \
  hostname \
  iproute \
  iptables-nft \
  java-17-openjdk-devel \
  java-17-openjdk-src \
  keychain \
  kmod \
  libevent-devel \
  make \
  man-db \
  man-pages \
  ncurses-devel \
  neovim \
  npm \
  openssh-clients \
  openssh-server \
  openssl \
  pass \
  pinentry \
  procps \
  restic \
  ripgrep \
  unzip

# SSH
# /var/run/utmp is touched as it is not in the image
# sshd would print an error message related to logout if utmp is missing
touch /var/run/utmp
ssh-keygen -A

# Docker
curl -sSo /etc/bash_completion.d/docker.sh \
  https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker
groupadd -g 2375 -r docker
mkdir /certs /certs/client
chmod 1777 /certs /certs/client

# Lazygit
LAZYGIT_VERSION=$(curl -sSLw '%{url_effective}' -o /dev/null https://github.com/jesseduffield/lazygit/releases/latest | awk -F / '{print $NF}')
LAZYGIT_SHORT_VERSION="$(printf '%s' "$LAZYGIT_VERSION" | grep -o '[^v]*')"
case $(uname -m) in
  aarch64) ARCH="arm64" ;;
  x86_64) ARCH="x86_64" ;;
esac
curl -sSL https://github.com/jesseduffield/lazygit/releases/download/"$LAZYGIT_VERSION"/lazygit_"$LAZYGIT_SHORT_VERSION"_Linux_"$ARCH".tar.gz |
  tar --no-same-owner --no-same-permissions -zxC /usr/local/bin lazygit

# tmux
# https://github.com/tmux/tmux/issues/3864
# Search is fixed but not yet released
# Build requirements: automake bison libevent-devel ncurses-devel
cd /tmp
git clone https://github.com/tmux/tmux.git
cd /tmp/tmux
git switch --detach 963e824f5f302894fe30e9ba4e4803d1008fe04e
sh autogen.sh
./configure --enable-sixel
make && make install

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
