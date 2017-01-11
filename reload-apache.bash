#!/bin/bash

if [[ ! $1 ]]; then

    echo "you need to feed this script with a host"
    exit 1

else
    PIHOST=$1
fi

echo
echo
echo "#############################################################"
echo "sudo /etc/init.d/apache2 restart ..."
echo "#############################################################"
ssh $USER@$PIHOST "sudo /etc/init.d/apache2 restart"

#echo ""
#echo "sudo /etc/init.d/memcached restart"
#ssh $USER@$PIHOST "sudo /etc/init.d/memcached restart"

