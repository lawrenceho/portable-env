#!/bin/sh
set -eu

# SSH
/usr/sbin/sshd -D -e &

# dnsmasq
/usr/local/bin/dnsmasq-entrypoint.sh &

# Docker
exec /usr/local/bin/dockerd-entrypoint.sh "$@"
