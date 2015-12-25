#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use JSON;

# generate the JSON conf file in perl !

my $khaospy_root = "/opt/khaospy";

my $conf_file="$khaospy_root/conf/daemon-runner.json";

my $conf = {
    piserver => [
        {
            script => "/opt/khaospy/libpy/khaospy-one-wired-receiver.py",
            params => "--host piloft", # can have param --port , defaults to 5001
        },
        {
            script => "/opt/khaospy/libpy/khaospy-one-wired-receiver.py",
            params => "--host pioldwifi",
        },
    ],
    piserver2 => [
        {
            script => "/opt/khaospy/libpy/khaospy-one-wired-receiver.py",
            params => "--host piloft",
        },
        {
            script => "/opt/khaospy/libpy/khaospy-one-wired-receiver.py",
            params => "--host pioldwifi",
        },
    ],
    piloft => [
        {
            script => "/opt/khaospy/libpy/khaospy-one-wired-sender.py",
            params => "", # can have param --port=number, defaults to 5001
        },
    ],
    pioldwifi => [
        {
            script => "/opt/khaospy/libpy/khaospy-one-wired-sender.py",
            params => "",
        },
    ],
};

my $json = JSON->new->allow_nonref;

burp ( $conf_file, $json->pretty->encode( $conf ) );

sub burp {
    my( $file_name ) = shift ;
    open( my $fh, ">" , $file_name ) || die "can't create $file_name $!" ;
    print $fh @_ ;
}

