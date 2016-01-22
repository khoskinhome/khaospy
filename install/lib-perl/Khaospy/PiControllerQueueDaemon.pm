package Khaospy::PiControllerQueueDaemon;
use strict;
use warnings;

# http://stackoverflow.com/questions/6024003/why-doesnt-zeromq-work-on-localhost/8958414#8958414
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html
# http://funcptr.net/2012/09/10/zeromq---edge-triggered-notification/

=pod PiControllerQueueDaemon

Receive's REQuests from Khaospy::Controls for Pi-run-controls

Queues the requests, and publishes them for a period of time.

PiController Daemons acknowlegde they've received the message.

If not the message will timeout, and get removed from the queue.

=cut

use Exporter qw/import/;
use Data::Dumper;
use JSON;
use Sys::Hostname;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_SUBSCRIBE
    ZMQ_FD
    ZMQ_PUB
    ZMQ_REP
);

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use zhelpers;

use Khaospy::Conf qw/
    validate_control_msg_json
    validate_control_msg_fields
/;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON
    true false
    ON OFF STATUS
    $PI_CONTROL_SEND_PORT
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_QUEUE_DAEMON_PUBLISH_EVERY_SECS
    $LOCALHOST
    $MESSAGE_TIMEOUT
);

use Khaospy::Log qw/ klog START FATAL ERROR WARN INFO DEBUG /;
our @EXPORT_OK = qw( run_controller_queue_daemon );

my $msg_queue = {};
my $zmq_publisher;

our $VERBOSE;

sub run_controller_queue_daemon {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;
    $VERBOSE = $opts->{verbose} || false;

    klog(START,"Controller Queue Daemon START");
    klog(START,"VERBOSE = ".( $VERBOSE ? "TRUE" : "FALSE" ));

    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );
    klog(INFO, "Publishing to $pub_to_port");

    my @w;

    my $zmq_reply_sock= zmq_socket($ZMQ_CONTEXT, ZMQ_REP);

    my $connect_str = "tcp://$LOCALHOST:$PI_CONTROL_SEND_PORT";
    klog(INFO, "Listening (REP) to $connect_str");

    if ( my $zmq_state = zmq_connect($zmq_reply_sock, $connect_str )){
        klog(FATAL, "zmq can't connect to $connect_str. status = $zmq_state. $!");
    };

    my $fh = zmq_getsockopt( $zmq_reply_sock, ZMQ_FD );

    push @w, anyevent_io( $fh, $zmq_reply_sock, \&queue_message );

    push @w, AnyEvent->timer(
        after    => 0.1,
        interval => $PI_CONTROLLER_QUEUE_DAEMON_PUBLISH_EVERY_SECS,
        cb       => \&timer_cb
    );

    # run the AnyEvent loop
    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;

}

sub anyevent_io {
    my ( $fh, $zmq_sock, $msg_handler ) = @_;
    return AnyEvent->io(
        fh   => $fh,
        poll => "r",
        cb   => sub {
            while (
                my $recvmsg = zmq_recvmsg( $zmq_sock, ZMQ_RCVMORE )
            ){
                $msg_handler->($zmq_sock, zmq_msg_data($recvmsg));
            }
        },
    );
}

sub timer_cb {
    klog(DEBUG,"in timer");

    # iterate over queued messages , and publish them
    # for control-daemons to pick up. hopefully.
    for my $mkey ( keys %$msg_queue ){
        my $msg_rh = $msg_queue->{$mkey}{hashref};

        klog(INFO, "Publish message $msg_queue->{$mkey}{json}");
        zmq_sendmsg( $zmq_publisher, $msg_queue->{$mkey}{json} );

        if ( $msg_rh->{request_epoch_time} < time - $MESSAGE_TIMEOUT ){
            klog(ERROR, "Msg timed out. $mkey");
            delete $msg_queue->{$mkey};
        }
    }
}

sub queue_message {
    my ($zmq_sock, $msg) = @_ ;

    klog(INFO, "Queuing message $msg");
    #my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;

    my $msg_p;
    eval{$msg_p = validate_control_msg_json($msg)};
    if ($@){
        klog(ERROR,"Problem with message format. $@");
        zmq_sendmsg( $zmq_sock, "ERROR. Not queued" );
        return;
    }

    $msg_queue->{$msg_p->{mkey}} = $msg_p;

    # have to reply to the requestor :
    klog(DEBUG, "Reply to requestor $msg");
    zmq_sendmsg( $zmq_sock, "queued $msg_p->{mkey}" );

    # publish this message for control-daemons to grab :
    klog(DEBUG, "Publish (first) message $msg");
    zmq_sendmsg( $zmq_publisher, $msg );

}

sub message_acknowleged_by_controller {
    my ($msg) = @_ ;
    # needs to be subscribed to all the control-daemons.
    klog(INFO, "Control Daemon Acknowledges message $msg");
    #my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;

}

1;

