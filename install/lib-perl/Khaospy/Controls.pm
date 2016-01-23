package Khaospy::Controls;
use strict;
use warnings;

# TODO . This needs renaming to Khaospy::OperateControl
# ( So Khaospy::Control package name can be used for something else )
#
# Used for sending a signal to a control.
#
# either signals orviboS20 directly or ZMQ_REQs the Khaospy::PiControlQueueDaemon with a message.

# exports one method, signal_control.

use Sys::Hostname;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use JSON;

use Time::HiRes qw/usleep time/;

use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_REQ
);

my $json = JSON->new->allow_nonref;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use zhelpers;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS
    $KHAOSPY_CONTROLS_CONF_FULLPATH

    $PI_CONTROL_SEND_PORT

    $ZMQ_REQUEST_TIMEOUT
);

use Khaospy::Conf qw(
    get_control_config
);

use Khaospy::Message qw(
    validate_action
    validate_control_msg_fields
);

use Khaospy::OrviboS20  qw//;

our @EXPORT_OK = qw(
    signal_control
);

our $verbose = false;

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

    print "Khaospy::Controls run orviboS20 command '$control_name $action'\n" if $verbose;

    my $control = get_control_config($control_name);
    # for orviboS20 only :
    if ( ! exists $control->{mac} ){
        croak "ERROR in config. Control '$control_name' doesn't have a 'mac' configured\n"
            ."   see $KHAOSPY_CONTROLS_CONF_FULLPATH\n";
    }

    return Khaospy::OrviboS20::signal_control(
        $control->{host} , $control->{mac}, $action
    );
}

sub _picontroller_command {
    my ( $control_name, $action ) = @_;

    print "Khaospy::Controls PRETEND RUN PICONTROLLER COMMAND $control_name $action\n";

    my $control = get_control_config($control_name);
    my $host = $control->{host};

    my $msg = {
          request_epoch_time => time,
          control_name       => $control_name,
          control_host       => $host,
          action             => $action,
          request_host       => hostname,
    };

    validate_control_msg_fields($msg);

    my $json_msg = $json->encode($msg);

    # TODO a $ZMQ_REQUEST_TIMEOUT on the following
    # and if it times out then log an error message.

    print "sending to $req_to_port \n";
    zhelpers::s_send( $zmq_req_sock, "$json_msg" );
    return zhelpers::s_recv($zmq_req_sock);
}


1;
