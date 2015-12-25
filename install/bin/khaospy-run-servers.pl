#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;
use Data::Dumper;

# see the crontab one from Pavel Shved
# http://stackoverflow.com/questions/1603109/how-to-make-a-python-script-run-like-a-service-or-daemon-in-linux

use JSON;

my $khaospy_root = "/opt/khaospy"

my $conf_file="$khaospy_root/conf/daemon-runner.json";

my $json = JSON->new->allow_nonref;

my $conf = $json->decode( slurp ($conf_file) );

print Dumper ($conf);

sub slurp {
    my ($file ) = @_;

    open( my $fh, $file ) or die "sudden flaming death\n";
    return do { local( $/ ) ; <$fh> } ;
}
