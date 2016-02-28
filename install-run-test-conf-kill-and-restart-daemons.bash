#!/bin/bash

if [[ ! $1 ]]; then
    echo "you need to feed this script with either piserver, piloft , piboiler, piold or pioldwifi"
    exit 1
fi

./install-to-pi-pi.bash $1
./run-test-conf-update-on-pi.bash $1
./run-kill-and-restart-daemons-on-pi.bash $1


