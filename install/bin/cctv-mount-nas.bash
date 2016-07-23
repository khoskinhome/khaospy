#!/bin/bash

cifs_username='khoskin'

function request_cifs_password {

    if [[ ! $cifs_password ]]; then
        read -s -p "Enter CIFS Password for user $cifs_username (NAS shares): " cifs_password
    fi
}

function mount_cifs () {

    dir=$1
    cifspath=$2
    echo "################"
    echo "mount cifs $dir"

    if [ `stat -fc%t:%T "$dir"` != `stat -fc%t:%T "$dir/.."` ]; then
        echo "    is already mounted"
    else
        echo "    is not mounted"

        request_cifs_password

        echo "sudo mount -t cifs $cifspath  $dir  -o  username=$cifs_username,password=XXXXXXXXX,noexec"
        sudo mount -t cifs $cifspath  $dir  -o  username=$cifs_username,password=$cifs_password,noexec
    fi
}

mount_cifs "/media/khoskin/nas_movies_n_tv"        "//nas/movies_n_tv"



