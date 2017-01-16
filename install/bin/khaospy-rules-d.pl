#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    true false
);

use Khaospy::RulesD qw(
    run_rules_daemon
);

use Getopt::Long;
my $verbose = false;

GetOptions ( "verbose" => \$verbose );

run_rules_daemon({ verbose => $verbose });
