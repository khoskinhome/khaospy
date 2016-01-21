#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::PiControllerDaemon qw(
    run_controller_daemon
);

use Khaospy::Constants qw(
    true false
);

#use Getopt::Long;
#GetOptions ( );

run_controller_daemon( { } );

exit 0;
