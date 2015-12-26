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
        "/opt/khaospy/bin/khaospy-one-wired-receiver-pioldwifi.bash",
        "/opt/khaospy/bin/khaospy-one-wired-receiver-piloft.bash",
#        "/opt/khaospy/bin/khaospy-orvibo-s20-radiator.pl",
    ],
#    piserver2 => [
#    ],
    piloft => [
        "/opt/khaospy/bin/khaospy-one-wired-sender.py",
        "/opt/khaospy/bin/khaospy-amelia-hackit-daemon.pl",
    ],
    piold => [
        "/opt/khaospy/bin/khaospy-one-wired-sender.py",
    ],
};

my $json = JSON->new->allow_nonref;

burp ( $conf_file, $json->pretty->encode( $conf ) );

sub burp {
    my( $file_name ) = shift ;
    open( my $fh, ">" , $file_name ) || die "can't create $file_name $!" ;
    print $fh @_ ;
}

