#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::PiControllerQueueDaemon qw(
    run_controller_queue_daemon
);

use Khaospy::Constants qw(
    true false
);

use Getopt::Long;

my $VERBOSE = false;

GetOptions ( "verbose" => \$VERBOSE );

run_controller_queue_daemon( { verbose => $VERBOSE } );

exit 0;
