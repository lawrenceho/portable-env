#!/bin/sh
set -eu

# SSH
/usr/sbin/sshd -D -e &

# dnsmasq
"$(dirname "$0")"/dnsmasq-entrypoint.sh &

# Docker
exec "$(dirname "$0")"/dockerd-entrypoint.sh "$@"
