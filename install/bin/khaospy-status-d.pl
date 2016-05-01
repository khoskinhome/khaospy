#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::StatusD qw(
    run_status_d
);

use Khaospy::Constants qw(
    true false
);

use Getopt::Long;

run_status_d( { } );

exit 0;
