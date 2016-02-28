package Khaospy::QueueCommand;
use strict;
use warnings;

# Used for sending a messages for a control to the CommandQueueDaemon.

use Sys::Hostname;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw(croak confess);

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
    $LOCALHOST
    $QUEUE_COMMAND_PORT

    MTYPE_QUEUE_COMMAND

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
    klogdebug
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

# TODO , could connect to a command-queue on a different host.
# would need to work out what hosts are running command queues.
#
# Currently if this is left as LOCALHOST it should fatal , if there isn't a command-queue-d running on the LOCALHOST.
my $connect_str = "tcp://$LOCALHOST:$QUEUE_COMMAND_PORT";

if ( my $zmq_state = zmq_connect($zmq_req_sock, $connect_str )){
    # zmq_connect returns zero on success.
    confess "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
};

sub queue_command {
    my ( $control_name, $action ) = @_;

    my $control = get_control_config($control_name);

    my $msg = {
        request_epoch_time  => time,
        control_name        => $control_name,
        control_host        => $control->{host},
        action              => $action,
        message_type        => MTYPE_QUEUE_COMMAND,
        request_host        => hostname,
        control_type        => get_hashval($control, "type"),
    };

    validate_control_msg_fields($msg);

    my $json_msg = $JSON->encode($msg);

    # TODO a $ZMQ_REQUEST_TIMEOUT on the following
    # and if it times out then log an error message.

    klogdebug "sending to $connect_str \n";
    zhelpers::s_send( $zmq_req_sock, "$json_msg" );
    return zhelpers::s_recv($zmq_req_sock);
}

1;
