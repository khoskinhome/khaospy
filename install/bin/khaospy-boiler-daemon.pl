#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::BoilerDaemon qw(
    run_boiler_daemon
);

run_boiler_daemon();

exit 0;
