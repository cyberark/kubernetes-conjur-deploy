#!/bin/bash
set -euo pipefail

echo "Starting follower services..."
/bin/keyctl session - /sbin/my_init &
sleep 5

if [[ -f "$SEEDFILE_DIR/follower-seed.tar" ]]; then
    echo "Unpacking seed..."
    evoke unpack seed $SEEDFILE_DIR/follower-seed.tar

    echo "Configuring follower..."
    evoke configure follower
fi

