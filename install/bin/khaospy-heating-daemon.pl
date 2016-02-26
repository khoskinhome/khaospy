#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    true false
);

use Khaospy::HeatingDaemon qw(
    run_heating_daemon
);

use Getopt::Long;
my $verbose = false;

GetOptions ( "verbose" => \$verbose );

run_heating_daemon({ verbose => $verbose });
