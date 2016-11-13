#!/bin/bash

if [[ ! $1 ]]; then

    echo "you need to feed this script with a host"
    exit 1

else
    PIHOST=$1
fi

USER=khoskin

./install-to-pi-pi.bash $PIHOST $USER

