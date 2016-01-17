#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

# This script is just to sending a test message to the picontroller daemon.

use Carp qw/croak/;
use Data::Dumper;
use JSON;
my $json = JSON->new->allow_nonref;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    $KHAOSPY_CONTROLS_CONF_FULLPATH
);

use Khaospy::Utils qw/timestamp/;

#  http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html
use ZMQ::LibZMQ3;
use ZMQ::Constants qw( ZMQ_PUB );
my $context   = zmq_init();
my $publisher = zmq_socket( $context, ZMQ_PUB );
zmq_bind( $publisher, "tcp://*:$HEATING_CONTROL_DAEMON_PUBLISH_PORT" );

use Getopt::Long;
my $verbose = false;

GetOptions ( "host"  => \$verbose );

sub send_control_message {
    my ( $control, $action ) = @_;

    print timestamp."Message to Pi Controller Daemon $control, $action\n";
    zmq_sendmsg( $publisher,
        $json->encode({
          EpochTime     => time,
          HomeAutoClass => 'PiController',
          Control       => $control,
          Action        => $action,
        }),
    );
}

1;
