#!/bin/bash

#
#PIHOST=piloft
#
##if [[ ! $1 ]]; then
##
##    echo "you need to feed this script with either piserver, piloft , piboiler, piold or pioldwifi"
##    exit 1
##
###    PIHOST=pimain
##
##else
##    PIHOST=$1
##fi
#
#USER=root
#
#PI_INSTALL_DIR=/etc/bind/
#
## sanity checks to make sure we're in the correct place :
#if [ ! -f scp-dns-to-hosts.bash ]; then
#
#    echo "can't find scp-dns-to-hosts.bash you mush be running this script from the wrong dir"
#    exit 1;
#
#fi
#
#if [ ! -d $PIHOST ]; then
#
#    echo "can't find dir $PIHOST you mush be running this script from the wrong dir"
#    exit 1;
#
#fi
#
#echo "#############################################################"
#echo "installing DNS to $USER@$PIHOST:$PI_INSTALL_DIR"
#echo "#############################################################"
#
##cd ./piloft/etc/bind/
#
#scp $PIHOST/$PI_INSTALL_DIR/db.192              $USER@$PIHOST:$PI_INSTALL_DIR
#scp $PIHOST/$PI_INSTALL_DIR/named.conf.options  $USER@$PIHOST:$PI_INSTALL_DIR
#scp $PIHOST/$PI_INSTALL_DIR/db.khaos            $USER@$PIHOST:$PI_INSTALL_DIR
#scp $PIHOST/$PI_INSTALL_DIR/named.conf.local    $USER@$PIHOST:$PI_INSTALL_DIR
#
#
#


