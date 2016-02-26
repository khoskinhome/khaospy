package Khaospy::QueueCommand;
use strict;
use warnings;

# Used for sending a messages for a control to the CommandQueueDaemon.


use Sys::Hostname;
use Exporter qw/import/;
use Data::Dumper;

use Time::HiRes qw/usleep time/;

use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_REQ
);

use zhelpers;

use Khaospy::Constants qw(
    $JSON
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS
    $KHAOSPY_CONTROLS_CONF_FULLPATH

    $PI_CONTROL_SEND_PORT

    $ZMQ_REQUEST_TIMEOUT
);

use Khaospy::Conf::Controls qw(
    get_control_config
);

use Khaospy::Message qw(
    validate_action
    validate_control_msg_fields
);

use Khaospy::Log qw(
    kloginfo
);

use Khaospy::Utils qw(
    get_hashval
);

use Khaospy::OrviboS20;

our @EXPORT_OK = qw(
    queue_command
);

my $zmq_context   = $ZMQ_CONTEXT;
my $zmq_req_sock = zmq_socket($zmq_context,ZMQ_REQ);
my $req_to_port = "tcp://*:$PI_CONTROL_SEND_PORT";
zmq_bind( $zmq_req_sock, $req_to_port );

sub queue_command {
    my ( $control_name, $action ) = @_;

    print "Khaospy::QueueCommand Run PiController COMMAND '$control_name $action'\n";

    my $control = get_control_config($control_name);

    my $msg = {
        request_epoch_time  => time,
        control_name        => $control_name,
        control_host        => $control->{host},
        action              => $action,
        request_host        => hostname,
        control_type        => get_hashval($control, "type"),
    };

    validate_control_msg_fields($msg);

    my $json_msg = $JSON->encode($msg);

    # TODO a $ZMQ_REQUEST_TIMEOUT on the following
    # and if it times out then log an error message.

    print "sending to $req_to_port \n";
    zhelpers::s_send( $zmq_req_sock, "$json_msg" );
    return zhelpers::s_recv($zmq_req_sock);
}

1;
