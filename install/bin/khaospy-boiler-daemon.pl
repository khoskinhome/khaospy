#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::BoilerDaemon qw(
    run_boiler_daemon
);

use Khaospy::Constants qw(
    true false
);

use Getopt::Long;

my $VERBOSE = false;

GetOptions ( "verbose" => \$VERBOSE );

run_boiler_daemon( { verbose => $VERBOSE } );

exit 0;
