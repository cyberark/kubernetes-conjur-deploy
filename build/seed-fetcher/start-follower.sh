#!/bin/bash
set -euo pipefail

if [[ -f "$SEEDFILE_DIR/follower-seed.tar" ]]; then
    echo "Unpacking seed..."
    evoke unpack seed $SEEDFILE_DIR/follower-seed.tar

    echo "Configuring follower..."
    evoke configure follower
fi

echo "Starting follower..."
exec /bin/keyctl session - /sbin/my_init