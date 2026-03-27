#!/usr/bin/env sh
set -eu

mkdir -p /var/run/sshd
exec /usr/sbin/sshd -D -e
