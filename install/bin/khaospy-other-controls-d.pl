#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

=pod
A daemon that runs commands for controls that are not on a PiHost

subscribes to hosts running Command-Queue-daemons on port 5061 for commands.
$PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT = 5061

publishes to tcp://*:5065 what the command did.
$OTHER_CONTROLS_DAEMON_SEND_PORT = 5065

=cut

use Khaospy::ControlsDaemon qw(
    run_daemon
);

use Khaospy::Constants qw(
    true false
    $OTHER_CONTROLS_DAEMON
    $OTHER_CONTROLS_DAEMON_TIMER
    $OTHER_CONTROLS_DAEMON_SEND_PORT
);

#use Getopt::Long;
#GetOptions ( );

run_daemon ( {
    daemon_name      => $OTHER_CONTROLS_DAEMON,
    daemon_timer     => $OTHER_CONTROLS_DAEMON_TIMER,
    daemon_send_port => $OTHER_CONTROLS_DAEMON_SEND_PORT,
    controller_class => "Khaospy::ControlOther"
} );

exit 0;
