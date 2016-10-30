package Khaospy::ControlsDaemon;
use strict;
use warnings;

=pod
Generalised Controls Daemon class.

Used by Pi-Controls-D and Other-Controls-D

=cut

use Try::Tiny;
use Time::HiRes qw/usleep time/;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak confess/;
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
    STATUS

    $COMMAND_QUEUE_DAEMON_SCRIPT
    $COMMAND_QUEUE_DAEMON_SEND_PORT

    MTYPE_POLL_UPDATE
    MTYPE_OPERATION_STATUS

    $MESSAGE_TIMEOUT

    $TIMER_AFTER_COMMON
);

use Khaospy::ControlOther;
use Khaospy::ControlPi;

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogextra klogdebug
);

use Khaospy::Message qw(
    validate_control_msg_json
);
use Khaospy::Utils qw(
    get_hashval
);

use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;
use zhelpers;

our @EXPORT_OK = qw(
    run_daemon
);

my $msg_actioned = {};

my $zmq_publisher;

my $DAEMON_NAME;
my $DAEMON_TIMER;
my $DAEMON_SEND_PORT;
my $CONTROLLER_CLASS;

sub run_daemon {
    my ($setup) = @_;

    $DAEMON_NAME        = get_hashval($setup, "daemon_name");
    $DAEMON_TIMER       = get_hashval($setup, "daemon_timer");
    $DAEMON_SEND_PORT   = get_hashval($setup, "daemon_send_port");
    $CONTROLLER_CLASS   = get_hashval($setup, "controller_class");
#    my $opts = @_;
#    $opts = {} if ! $opts;

    klogstart "$DAEMON_NAME START";

    $CONTROLLER_CLASS->init_controls();

    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$DAEMON_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );

    my @w;

    for my $sub_host (
        @{get_pi_hosts_running_daemon(
            $COMMAND_QUEUE_DAEMON_SCRIPT
        )}
    ){
        push @w, zmq_anyevent({
            zmq_type    => ZMQ_SUB,
            host        => $sub_host,
            port        => $COMMAND_QUEUE_DAEMON_SEND_PORT,
            msg_handler => \&controller_message,
            klog        => true,
        });
    }

    push @w, AnyEvent->timer(
        after    => $TIMER_AFTER_COMMON,
        interval => $DAEMON_TIMER,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {
    klogdebug "in timer ";

    $CONTROLLER_CLASS->poll_controls(\&poll_callback);

    for my $mkey ( keys %$msg_actioned ){
        my $r_epoch_t = get_hashval(get_hashval($msg_actioned,$mkey), 'request_epoch_time');

        next if ( $r_epoch_t > time - $MESSAGE_TIMEOUT );

        klogextra "deleting mkey '$mkey'";
        delete $msg_actioned->{$mkey}
    }
}

sub poll_callback {
    my ( $poll_state ) = @_;


    $poll_state->{message_type} =
        MTYPE_POLL_UPDATE;
    $poll_state->{request_epoch_time} = time;
    $poll_state->{action}             = STATUS;
    $poll_state->{poll_epoch_time}    = time;
    $poll_state->{message_from}       = $DAEMON_NAME;
    my $json_msg = $JSON->encode($poll_state);
    zhelpers::s_send( $zmq_publisher, "$json_msg" );
}

sub controller_message {
    my ($zmq_sock, $msg, $param ) = @_;

    my $msg_val_struct;
    eval { $msg_val_struct = validate_control_msg_json($msg); };
    if ( $@ || ! $msg_val_struct ) {
        klogerror ( "validate control msg json :: $@ :: $msg" );
        return;
    }

    my $msg_rh = get_hashval($msg_val_struct,  'hashref');
    my $mkey   = get_hashval($msg_val_struct,  'mkey');

    my $request_epoch_time = get_hashval($msg_rh, 'request_epoch_time');
    my $control_name       = get_hashval($msg_rh, 'control_name');
    my $action             = get_hashval($msg_rh, 'action');
    my $request_host       = get_hashval($msg_rh, 'request_host') || "";

    my $control = get_control_config($control_name);

    if ( ! exists $control->{$CONTROLLER_CLASS->check_host_field} ){
        klogdebug "control $control_name is not of a type controlled by this daemon";
        return;
    }

    my $daemon_host = $control->{$CONTROLLER_CLASS->check_host_field};

    # TODO if daemon_host doesn't have a '.' then only check up to the first '.' in the hostname
    # otherwise check the entire hostname
    if ( $daemon_host ne hostname ){
        klogdebug "control $control_name is not controlled by this host";
        return;
    }

    kloginfo  "Message '$mkey' received. ";
    klogdebug "Message Dump", ($msg_rh);

    try {

        if ( exists $msg_actioned->{$mkey} ){

            kloginfo "Message '$mkey' already actioned";

        } else {
            my $status
                = $CONTROLLER_CLASS->operate_control($control_name, $control, $action);

            # Below, the $return_msg needs to be constructed exactly in this way to ensure
            # duplicate keys ( mainly request_epoch_time from $status)
            # gets overwritten by the later keys
            #
            # The keys control_name, action, request_host and request_epoch_time are explicitly
            # stated at the end because they are crucial for the "mkey" message signature.
            #
            # So the below code will break with unthinking movement of key defs :
            my $return_msg = {
              %$status,
              %$msg_rh,

              action_epoch_time  => time,
              message_from       => $DAEMON_NAME,
              message_type       => MTYPE_OPERATION_STATUS,

              request_epoch_time => $request_epoch_time,
              control_name       => $control_name,
              action             => $action,
              request_host       => $request_host,
            };

            $msg_actioned->{$mkey}{json_send} = $JSON->encode($return_msg);
            $msg_actioned->{$mkey}{request_epoch_time} = $request_epoch_time;
        }

        zhelpers::s_send( $zmq_publisher, $msg_actioned->{$mkey}{json_send} );

    } catch {
        if (ref $_ eq 'KhaospyExcept::UnhandledControl'){
            klogdebug $_;
        } else {
            $_->throw if ( ref $_ and $_->can("throw"));
            klogfatal $_;
        }
    }
}

1;
