package Khaospy::PiControllerDaemon;
use strict;
use warnings;

=pod

A daemon that runs commands on a PiController and :

    subscribes to all hosts tcp://all-hosts:5061 for commands.
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT = 5061

    publishes to tcp://*:5062 what the command did.
    $PI_CONTROLLER_DAEMON_SEND_PORT = 5062

=cut

use Time::HiRes qw/usleep time/;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use Sys::Hostname;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_SUBSCRIBE
    ZMQ_FD
    ZMQ_PUB
    ZMQ_SUB
);

use Khaospy::Conf::Controls qw(
    get_control_config
);

use Khaospy::Conf::PiHosts qw/
    get_pi_hosts_running_daemon
/;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON
    true false

    $PI_CONTROLLER_DAEMON

    $KHAOSPY_PI_CONTROLLER_QUEUE_DAEMON_SCRIPT
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT

    $PI_CONTROLLER_DAEMON_SEND_PORT
);

use Khaospy::ControlPi qw(
    init_pi_controls
    operate_control
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

use Khaospy::Message qw(
    validate_control_msg_fields
);

use Khaospy::Utils qw( timestamp );

use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;
use zhelpers;

our @EXPORT_OK = qw( run_controller_daemon );

our $PUBLISH_STATUS_EVERY_SECS = 5;

# TODO use this to log messages received and only action them once.
# my $msg_received = {};

my $zmq_publisher;

sub run_controller_daemon {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;

    klogstart "Controller Daemon START";

    init_pi_controls();

    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$PI_CONTROLLER_DAEMON_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );

    my @w;

    for my $sub_host (
        @{get_pi_hosts_running_daemon(
            $KHAOSPY_PI_CONTROLLER_QUEUE_DAEMON_SCRIPT
        )}
    ){
        push @w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT,
            msg_handler       => \&controller_message,
            klog              => true,
        });
    }

    push @w, AnyEvent->timer(
        after    => 0.1, # TODO. MAGIC NUMBER . should be in Constants.pm or a json-config. dunno. but not here.
        interval => $PUBLISH_STATUS_EVERY_SECS,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {
    klogdebug "in timer ";

    # TODO clean up $msg_received with messages over timeout.

}

sub controller_message {
    my ($zmq_sock, $msg, $param ) = @_;

    my $msg_decoded;
    eval{$msg_decoded = $JSON->decode( $msg );};

    if ($@) {
        klogerror "ERROR. JSON decode of message failed. $@";
        return;
    }

    my $request_epoch_time = $msg_decoded->{request_epoch_time};
    my $control_name       = $msg_decoded->{control_name};
    my $control_host       = $msg_decoded->{control_host};
    my $action             = $msg_decoded->{action};
    my $request_host       = $msg_decoded->{request_host};

    kloginfo  "Message received. '$control_name' '$action'";
    klogdebug "Message Dump", ($msg_decoded);

    my $control = get_control_config($control_name);

    if ( $control->{host} ne hostname ) {
        kloginfo "control $control_name is not controlled by this host";
        return;
    }

# TODO check in msg_received has already been actioned. Is this necessary?

    my $status
        = operate_control($control_name, $control, $action);

    my $return_msg = {
      request_epoch_time => $request_epoch_time,
      control_name       => $control_name,
      control_host       => $control_host,
      action             => $action,
      request_host       => $request_host,
      action_epoch_time  => time,
      message_from       => $PI_CONTROLLER_DAEMON,
      %$status,
    };

# TODO log msg just actioned in :
#    $msg_received = {};

    validate_control_msg_fields($return_msg);

    my $json_msg = $JSON->encode($return_msg);

    zhelpers::s_send( $zmq_publisher, "$json_msg" );

}

1;
