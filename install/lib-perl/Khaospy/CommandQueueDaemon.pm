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

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_SUBSCRIBE
    ZMQ_FD
    ZMQ_PUB
    ZMQ_SUB
    ZMQ_REP
);

use zhelpers;

use Khaospy::Message qw/
    validate_control_msg_json
    validate_control_msg_fields
/;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON
    true false
    ON OFF STATUS

    $PI_CONTROLLER_QUEUE_DAEMON
    $PI_CONTROLLER_QUEUE_DAEMON_TIMER

    $QUEUE_COMMAND_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SCRIPT
    $LOCALHOST
    $MESSAGE_TIMEOUT

    $OTHER_CONTROLS_DAEMON
    $OTHER_CONTROLS_DAEMON_SCRIPT
    $OTHER_CONTROLS_DAEMON_SEND_PORT
);

use Khaospy::Conf::Controls qw(
    get_controls_conf
);

use Khaospy::Conf::PiHosts qw/
    get_pi_hosts_running_daemon
    get_pi_hosts_conf
/;

use Khaospy::ZMQAnyEvent qw(
    zmq_anyevent
);

use Khaospy::Log qw(
    klog START FATAL ERROR WARN INFO DEBUG
    kloginfo klogfatal klogdebug
);

our @EXPORT_OK = qw( run_command_queue_daemon );

my $msg_queue = {};
my $zmq_publisher;

our $VERBOSE;

sub run_command_queue_daemon {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;
    $VERBOSE = $opts->{verbose} || false;

    klog(START,"Controller Queue Daemon START");
    klog(START,"VERBOSE = ".( $VERBOSE ? "TRUE" : "FALSE" ));

    # TODO only running these to validate the confs.
    # could possibly do with a "validate_all_confs" or sumin' like that.
    get_controls_conf();
    get_pi_hosts_conf();

    my @w;

    # Listen for messages to go onto the queue.
    push @w, zmq_anyevent({
        zmq_type          => ZMQ_REP,
        host              => $LOCALHOST,
        port              => $QUEUE_COMMAND_PORT,
        msg_handler       => \&queue_message,
        klog              => true,
    });

    # Publisher to push the queue out to controllers.
    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );
    klog(INFO, "Publishing to $pub_to_port");


    my $count_zmq_subs = 0;
    # Listen for the Pi Control Daemons return messages.
    for my $sub_host (
        @{get_pi_hosts_running_daemon(
            $PI_CONTROLLER_DAEMON_SCRIPT
        )}
    ){
        $count_zmq_subs++;
        push @w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $PI_CONTROLLER_DAEMON_SEND_PORT,
            msg_handler       => \&message_from_controller,
            msg_handler_param => "",
            klog              => true,
        });
    }

    # Listen for the other controls daemon.
    for my $sub_host (
        @{get_pi_hosts_running_daemon( $OTHER_CONTROLS_DAEMON_SCRIPT)}
    ){
        $count_zmq_subs++;
        push @w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $OTHER_CONTROLS_DAEMON_SEND_PORT,
            msg_handler       => \&message_from_controller,
            msg_handler_param => "",
            klog              => true,
        });
    }

    croak "No Control Daemons configured. Command-Queue-D Can't subscribe to anything."
        if ! $count_zmq_subs;

    # Register the timer :
    push @w, AnyEvent->timer(
        after    => 0.1,
        interval => $PI_CONTROLLER_QUEUE_DAEMON_TIMER,
        cb       => \&timer_cb
    );

    # Run the AnyEvent loop
    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {
    klog(DEBUG,"in timer");

    # iterate over queued messages , and publish them
    # for control-daemons to pick up. hopefully.
    for my $mkey ( keys %$msg_queue ){
        my $msg_rh = $msg_queue->{$mkey}{hashref};

        klog(INFO, "Publish message $msg_queue->{$mkey}{json_from}");
        zmq_sendmsg( $zmq_publisher, $msg_queue->{$mkey}{json_from} );

        if ( $msg_rh->{request_epoch_time} < time - $MESSAGE_TIMEOUT ){
            klog(ERROR, "Msg timed out. $mkey");
            delete $msg_queue->{$mkey};
        }
    }
}

sub message_from_controller {
    my ($zmq_sock, $msg, $param ) = @_;

    kloginfo "$param FROM CONTROLLER : $msg";

    my $mkey = validate_control_msg_json($msg)->{mkey};

    if ( exists $msg_queue->{$mkey} ){
        kloginfo "Deleting message $mkey";
        delete $msg_queue->{$mkey};
    } else {
        klogdebug "Don't have message $mkey in queue";
    }
}

sub queue_message {
    my ($zmq_sock, $msg, $param ) = @_;

    klog(INFO, "Queuing message $msg");
    #my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;

    my $msg_p;
    eval{$msg_p = validate_control_msg_json($msg)};
    if ($@){
        klog(ERROR,"Problem with message format. $@");
        zmq_sendmsg( $zmq_sock, "ERROR. Not queued" );
        return;
    }

    my $mkey = $msg_p->{mkey};

    my $new_msg = clone($msg_p->{hashref});
    $new_msg->{message_from} = $PI_CONTROLLER_QUEUE_DAEMON;
    $msg_p->{json_from} = $JSON->encode($new_msg);

    $msg_queue->{$mkey} = $msg_p;

    # have to reply to the requestor :
    klog(DEBUG, "Reply to requestor $msg");
    zmq_sendmsg( $zmq_sock, "queued $msg_p->{mkey}" );

    # publish this message for control-daemons to grab :
    klog(DEBUG, "Publish (first) message $msg");
    zmq_sendmsg( $zmq_publisher, $msg_queue->{$mkey}{json_from} );

}

1;

