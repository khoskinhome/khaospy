#!/bin/bash


if [[ ! $1 ]]; then

    PIHOST=pimain

else
    PIHOST=$1
fi

USER=khoskin

PI_INSTALL_DIR=/opt/khaospy


ssh $USER@$PIHOST "if [ ! -d $PI_INSTALL_DIR ] ; then sudo mkdir -p $PI_INSTALL_DIR; fi;"

# sanity checks to make sure we're in the correct place :
if [ ! -f install-to-pi.bash ]; then

    echo "can't find install-to-pi.bash you mush be running this script from the wrong dir"
    exit 1;

fi

if [ ! -d install ]; then

    echo "can't find dir 'install' you mush be running this script from the wrong dir"
    exit 1;

fi

echo "#############################################################"
echo "installing to $USER@$PIHOST:$PI_INSTALL_DIR"
echo "#############################################################"

cd ./install

tar zcf - ./ | ssh $USER@$PIHOST "( cd $PI_INSTALL_DIR ; sudo tar zxvf - )"


