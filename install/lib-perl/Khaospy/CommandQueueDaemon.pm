package Khaospy::CommandQueueDaemon;
use strict;
use warnings;

# http://stackoverflow.com/questions/6024003/why-doesnt-zeromq-work-on-localhost/8958414#8958414
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html
# http://funcptr.net/2012/09/10/zeromq---edge-triggered-notification/

=pod CommandQueueDaemon

Receive's messages from Khaospy::QueueCommand for Pi-run-controls

Queues the requests, and publishes them for a period of time.

PiController Daemons acknowlegde they've received the message.

If not the message will timeout, and get removed from the queue.

=cut

use Exporter qw(import);
use Data::Dumper;
use JSON;
use Sys::Hostname;
use Clone qw(clone);
use Carp qw(croak);
use Time::HiRes qw(time);

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_PUB
    ZMQ_REP
);

use zhelpers;

use Khaospy::Message qw(
    validate_control_msg_json
);

use Khaospy::Conf::Global qw(
    gc_QUEUE_COMMAND_PORT
    gc_COMMAND_QUEUE_DAEMON_SEND_PORT
);

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON
    true false
    ON OFF STATUS

    $COMMAND_QUEUE_DAEMON
    $COMMAND_QUEUE_DAEMON_TIMER
    $COMMAND_QUEUE_DAEMON_BROADCAST_TIMER

    $LOCALHOST
    $MESSAGE_TIMEOUT

    MYTPE_COMMAND_QUEUE_BROADCAST

);

use Khaospy::Conf::Controls qw(
    get_controls_conf
);

use Khaospy::Conf::PiHosts qw(
    get_pi_hosts_conf
);

use Khaospy::ZMQAnyEvent qw(
    zmq_anyevent
    subscribe_to_controller_daemons
);

use Khaospy::Log qw(
    klog ERROR WARN INFO DEBUG
    klogerror klogstart kloginfo klogfatal klogdebug
);

our @EXPORT_OK = qw( run_command_queue_daemon );

my $msg_queue = {};
my $zmq_publisher;

our $VERBOSE;

sub run_command_queue_daemon {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;
    $VERBOSE = $opts->{verbose} || false;

    klogstart "Controller Queue Daemon START";
    klogstart "VERBOSE = ".( $VERBOSE ? "TRUE" : "FALSE" );

    # running these to validate the confs :
    get_controls_conf();
    get_pi_hosts_conf();

    my @w;

    # Listen for messages to go onto the queue.
    push @w, zmq_anyevent({
        zmq_type          => ZMQ_REP,
        bind              => true,
        host              => $LOCALHOST,
        port              => gc_QUEUE_COMMAND_PORT,
        msg_handler       => \&queue_message,
        klog              => true,
    });

    # Publisher to push the queue out to controllers.
    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:gc_COMMAND_QUEUE_DAEMON_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );
    kloginfo "Publishing to $pub_to_port";

    subscribe_to_controller_daemons(
        \@w,
        {
            msg_handler       => \&message_from_controller,
            msg_handler_param => "",
            klog              => true,
        }
    );

    # Register the timer :
    push @w, AnyEvent->timer(
        after    => 0.1,
        interval => $COMMAND_QUEUE_DAEMON_TIMER,
        cb       => \&timer_cb
    );

    # Run the AnyEvent loop
    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {
    klogdebug "in timer";

    # iterate over queued messages , and publish them
    # for control-daemons to pick up. hopefully.
    for my $mkey ( keys %$msg_queue ){
        my $msg_rh = $msg_queue->{$mkey}{hashref};

        next if $msg_rh->{last_broadcast_time}
            + $COMMAND_QUEUE_DAEMON_BROADCAST_TIMER
                > time;

        kloginfo "Publish message $mkey";
        zmq_sendmsg( $zmq_publisher, $msg_queue->{$mkey}{json_from} );
        $msg_rh->{last_broadcast_time} = time;

        if ( $msg_rh->{request_epoch_time} < time - $MESSAGE_TIMEOUT ){
            klogerror "Msg timed out. $mkey";
            delete $msg_queue->{$mkey};
        }
    }
}

sub message_from_controller {
    my ($zmq_sock, $msg, $param ) = @_;


    my $mkey ;
    eval {
        $mkey = validate_control_msg_json($msg)->{mkey};
    };
    if ($@){
        klogerror "Problem with message format. $@";
        return;
    }

    kloginfo "$param FROM CONTROLLER : '$mkey' ";

    if ( exists $msg_queue->{$mkey} ){
        kloginfo "Deleting message $mkey";
        delete $msg_queue->{$mkey};
    } else {
        kloginfo "Don't have message $mkey in queue";
    }
}

sub queue_message {
    my ($zmq_sock, $msg, $param ) = @_;

    #my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;

    my $msg_p;
    eval{$msg_p = validate_control_msg_json($msg)};
    if ($@){
        klogerror "Problem with message format. $@";
        zmq_sendmsg( $zmq_sock, "ERROR. Not queued" );
        return;
    }

    my $mkey = $msg_p->{mkey};
    kloginfo "Queuing message '$mkey'";

    my $msg_p_rh = $msg_p->{hashref};
    $msg_p_rh->{message_from} = $COMMAND_QUEUE_DAEMON;
    $msg_p_rh->{message_type} = MYTPE_COMMAND_QUEUE_BROADCAST;
    $msg_p_rh->{last_broadcast_time} = time;
    $msg_p->{json_from} = $JSON->encode($msg_p_rh);

    $msg_queue->{$mkey} = $msg_p;

    # have to reply to the requestor :
    klogdebug "Reply to requestor $msg";
    zmq_sendmsg( $zmq_sock, "queued $msg_p->{mkey}" );

    # publish this message for control-daemons to grab :
    klogdebug "Publish (first) message $msg";
    zmq_sendmsg( $zmq_publisher, $msg_queue->{$mkey}{json_from} );

}

1;

