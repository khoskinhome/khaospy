#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::OneWireThermometer qw(
    run_one_wire_thermometer_daemon
);

use Khaospy::Constants qw(
    true false
);

use Getopt::Long;

run_one_wire_thermometer_daemon ( { } );

exit 0;
