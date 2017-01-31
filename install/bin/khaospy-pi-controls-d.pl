#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

=pod

A daemon that runs commands for controls that are not on a PiHost

subscribes to hosts running Command-Queue-daemons on port 5061 for commands.
gc_COMMAND_QUEUE_DAEMON_SEND_PORT = 5061

publishes to tcp://*:5065 what the command did.
gc_PI_CONTROLLER_DAEMON_SEND_PORT = 5062

=cut

use Khaospy::ControlsDaemon qw(
    run_daemon
);

use Khaospy::Conf::Global qw(
    gc_PI_CONTROLLER_DAEMON_SEND_PORT
);

use Khaospy::Constants qw(
    true false
    $PI_CONTROLLER_DAEMON
    $PI_CONTROLLER_DAEMON_TIMER
);

run_daemon ( {
    daemon_name      => $PI_CONTROLLER_DAEMON,
    daemon_timer     => $PI_CONTROLLER_DAEMON_TIMER,
    daemon_send_port => gc_PI_CONTROLLER_DAEMON_SEND_PORT,
    controller_class => "Khaospy::ControlPi"
} );

exit 0;
