package Khaospy::OperateControls;
use strict;
use warnings;

# TODO . This needs renaming to either :
# Khaospy::OperateControlRequest
# Khaospy::ControlRequest
#
# Used for sending a signal to a control.
#
# either signals orviboS20 directly or ZMQ_REQs the Khaospy::PiControlQueueDaemon with a message.

# exports one method, signal_control.

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

use Khaospy::OrviboS20;

our @EXPORT_OK = qw(
    signal_control
);

my $zmq_context   = $ZMQ_CONTEXT;
my $zmq_req_sock = zmq_socket($zmq_context,ZMQ_REQ);
my $req_to_port = "tcp://*:$PI_CONTROL_SEND_PORT";
zmq_bind( $zmq_req_sock, $req_to_port );

sub signal_control {
    my ( $control_name, $action ) = @_;

    my $control = get_control_config($control_name);

    if ($control->{type} eq 'orviboS20'){
        return _orvibo_command( $control_name, $action);
    }
    return _picontroller_command( $control_name, $action);
}

sub _orvibo_command {
    my ( $control_name, $action ) = @_;

    kloginfo "Khaospy::OperateControls run orviboS20 command '$control_name $action'";

    my $control = get_control_config($control_name);

    return Khaospy::OrviboS20::signal_control(
        $control->{host} , $control->{mac}, $action
    );
}

sub _picontroller_command {
    my ( $control_name, $action ) = @_;

    print "Khaospy::OperateControls Run PiController COMMAND '$control_name $action'\n";

    my $control = get_control_config($control_name);

    my $msg = {
          request_epoch_time => time,
          control_name       => $control_name,
          control_host       => $control->{host},
          action             => $action,
          request_host       => hostname,
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
