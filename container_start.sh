#!/usr/bin/env sh
set -eu

mkdir -p /var/run/sshd
if [ -n "${USERPASSWD:-}" ]; then
  printf "%s:%s\n" "${USERNAME}" "${USERPASSWD}" | chpasswd
fi
exec /usr/sbin/sshd -D -e
