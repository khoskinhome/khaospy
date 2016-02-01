package Khaospy::BoilerMessage;
use strict;
use warnings;

use Carp qw/croak/;
use Data::Dumper;
use Exporter qw/import/;
use JSON;
my $json = JSON->new->allow_nonref;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $HEATING_CONTROL_DAEMON_PUBLISH_PORT
);

use Khaospy::Utils qw/timestamp/;

#  http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html
use ZMQ::LibZMQ3;
use ZMQ::Constants qw( ZMQ_PUB );
my $publisher = zmq_socket( $ZMQ_CONTEXT, ZMQ_PUB );
zmq_bind( $publisher, "tcp://*:$HEATING_CONTROL_DAEMON_PUBLISH_PORT" );

our @EXPORT_OK = qw(
    send_boiler_control_message
);

# This module is just to abstract the sending of a message to the boiler daemon.
# This module should only be used by the heating-control-daemon.
# It is not for use by the boiler daemon, which listens for these messages.

sub send_boiler_control_message {
    my ( $control, $action ) = @_;

    print timestamp."Message to Boiler Daemon $control, $action\n";
    zmq_sendmsg( $publisher,
        $json->encode({
          EpochTime     => time,
          HomeAutoClass => 'boilerControl',
          Control       => $control,
          Action        => $action,
        }),
    );
}

1;
