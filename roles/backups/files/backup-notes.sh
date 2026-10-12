#!/usr/bin/env bash

set -euxo pipefail

restic backup -r ~/backups/notes ~/notes
