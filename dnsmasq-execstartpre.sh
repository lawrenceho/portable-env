#!/bin/sh
set -eu

# https://github.com/koalaman/shellcheck/issues/2555
# shellcheck disable=SC3040
(set -o pipefail 2>/dev/null) && set -o pipefail

# Get docker0 IP address
DOCKER0_IP="$(ip -o -4 addr show docker0 | tr -s ' ' | cut -d ' ' -f 4 | cut -d '/' -f 1)"

# Add listen-address dnsmasq config entry
printf 'listen-address=%s # added by dnsmasq-execstartpre.sh\n' "$DOCKER0_IP" >>/etc/dnsmasq.conf
