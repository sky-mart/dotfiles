#!/usr/bin/env bash

set -euxo pipefail

mkdir -p /tmp/docs && \
    sshfs ftpvlad@h3007161.stratoserver.net:/home/ftpvlad /tmp/docs && \
    restic backup -r ~/backups/docs -e "\.*" /tmp/docs && \
    fusermount -u /tmp/docs
