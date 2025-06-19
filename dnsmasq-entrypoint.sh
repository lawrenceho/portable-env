#!/bin/sh
set -eu

# https://github.com/koalaman/shellcheck/issues/2555
# shellcheck disable=SC3040
(set -o pipefail 2>/dev/null) && set -o pipefail

# Wait until docker0 becomes available
while ! ip -o -4 addr show docker0 >/dev/null 2>&1; do
  printf 'dnsmasq-entrypoint.sh: Waiting for docker0...\n'
  sleep 1
done

# Get docker0 IP address
DOCKER0_IP="$(ip -o -4 addr show docker0 | tr -s ' ' | cut -d ' ' -f 4 | cut -d '/' -f 1)"

# Add nameserver entry to be picked up by containers
printf 'nameserver %s\n' "$DOCKER0_IP" >>/etc/resolv.conf

# Run dnsmasq
exec /usr/sbin/dnsmasq -k -a "$DOCKER0_IP" -R -S 127.0.0.11
