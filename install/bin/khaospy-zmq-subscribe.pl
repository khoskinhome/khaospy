#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::ZMQSubscribeAllPublishers qw(
    run_subscribe_all
);

use Khaospy::Constants qw(
    true false
);

use Getopt::Long;

=pod

CLI switches say "just listen to the port for this" :
    pi-control
    other-control
    command-queue
    status
    mac
    one-wire

=cut

my %opts = (
    "host=s"        => \my $host,
    "log-level=s"   => \my $log_level,
    "w|ow|one-wire"      => \my $one_wire,
    "c|command-queue" => \my $command_queue,
    "p|pi-control"    => \my $pi_control,
    "o|other-control" => \my $other_control,
    "s|status"        => \my $status,
    "m|mac"           => \my $mac,
    "f|filter-control=s"=> \my $filter_control,
    "h|help"        => \my $help,
);

GetOptions (%opts);

if ( $help ) {
    print "CLI params :\n";
    print join "\n", keys %opts;
    exit 0 ;
}

run_subscribe_all( {
    'host'          => $host,
    'log-level'     => $log_level,
    "one-wire"      => $one_wire,
    "command-queue" => $command_queue,
    "pi-control"    => $pi_control,
    "other-control" => $other_control,
    "status"        => $status,
    "mac"           => $mac,
    "filter-control"=> $filter_control,
} );

exit 0;

