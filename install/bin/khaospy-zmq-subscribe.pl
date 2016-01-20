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
    control
    control-queue
    status
    mac
    ping
    one-wire

=cut

GetOptions (
    "host=s"        => \my $host,
    "log-level=s"   => \my $log_level,
    "one-wire"      => \my $one_wire,
    "control-queue" => \my $control_queue,
    "control"       => \my $control,
    "status"        => \my $status,
    "mac"           => \my $mac,
    "ping"          => \my $ping,

);

run_subscribe_all( {
    'host'          => $host,
    'log-level'     => $log_level,
    "one-wire"      => $one_wire,
    "control-queue" => $control_queue,
    "control"       => $control,
    "status"        => $status,
    "mac"           => $mac,
    "ping"          => $ping,
} );

exit 0;

