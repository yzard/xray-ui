#!/bin/sh

BACKUP_DIR="/root/backup_binary"
BINARY_DIR="/root/bin"

set -o errexit
set -o nounset

# Create initial configuration:
mkdir -p /etc/caddy

if [ ! -f /etc/caddy/Caddyfile ];
then
    cp -r /root/caddy/* /etc/caddy/
fi

for file in `ls ${BACKUP_DIR}`;
do
    if [ ! -f "${BINARY_DIR}/${file}" ];
    then
        cp ${BACKUP_DIR}/${file} ${BINARY_DIR}/${file}
    fi
done

# Execute passed command:
exec "$@"
