#!/bin/bash

if [[ ! $1 ]]; then

    echo "you need to feed this script with either piserver, piloft , piboiler, piold or pioldwifi"
    exit 1

else
    PIHOST=$1
fi

USER=pi

PI_INSTALL_DIR=/opt/khaospy

echo "#############################################################"
echo "KILL all and restart all khaospy daemons on  $USER@$PIHOST"
echo "#############################################################"

ssh $USER@$PIHOST "sudo /opt/khaospy/bin/khaospy-ps.pl -k"
ssh $USER@$PIHOST "sudo /opt/khaospy/bin/khaospy-run-daemons.pl"


