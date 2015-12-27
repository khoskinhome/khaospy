#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use JSON;
use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw/burp/;
use Khaospy::Constants qw(
    $KHAOSPY_CONF_DIR
    $KHAOSPY_ALL_CONFS
);

# generate the daemon-runner JSON conf file in perl !

my $json = JSON->new->allow_nonref;

for my $conf_file ( keys %$KHAOSPY_ALL_CONFS ) {

    print "Generating $KHAOSPY_CONF_DIR/$conf_file\n";

    burp ( "$KHAOSPY_CONF_DIR/$conf_file",
            $json->pretty->encode( $KHAOSPY_ALL_CONFS->{$conf_file} )
    );
}

