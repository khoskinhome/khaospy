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
    ping
    one-wire

=cut

GetOptions (
    "host=s"        => \my $host,
    "log-level=s"   => \my $log_level,
    "one-wire"      => \my $one_wire,
    "command-queue" => \my $command_queue,
    "pi-control"    => \my $pi_control,
    "other-control" => \my $other_control,
    "status"        => \my $status,
    "mac"           => \my $mac,
    "ping"          => \my $ping,

);

run_subscribe_all( {
    'host'          => $host,
    'log-level'     => $log_level,
    "one-wire"      => $one_wire,
    "command-queue" => $command_queue,
    "pi-control"    => $pi_control,
    "other-control" => $other_control,
    "status"        => $status,
    "mac"           => $mac,
    "ping"          => $ping,
} );

exit 0;

