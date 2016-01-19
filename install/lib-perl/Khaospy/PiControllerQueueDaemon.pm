package Khaospy::PiControllerQueueDaemon;
# http://stackoverflow.com/questions/6024003/why-doesnt-zeromq-work-on-localhost/8958414#8958414
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html
# http://funcptr.net/2012/09/10/zeromq---edge-triggered-notification/

=pod


=cut

use warnings;

use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
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

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS
    $PI_RULES_DAEMON_SEND_PORT
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
);

use Khaospy::Conf qw(
    get_controls_conf
    get_pi_controller_conf
);

use Khaospy::Utils qw( timestamp );

our @EXPORT_OK = qw( run_controller_queue_daemon );

our $PUBLISH_STATUS_EVERY_SECS = 5;

my $JSON = JSON->new->allow_nonref;

our $VERBOSE;

sub run_controller_queue_daemon {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;
    $VERBOSE = $opts->{verbose} || false;

    print "#############\n";
    print timestamp."Controller Daemon START\n";
    print timestamp."VERBOSE = ".( $VERBOSE ? "TRUE" : "FALSE" )."\n";

    $controls_conf = get_controls_conf();
    $pi_controller_conf = get_pi_controller_conf();
    #print "\n".Dumper($controls_conf)."\n";
    print "\n".Dumper($pi_controller_conf)."\n";

    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );
    print timestamp. "Publishing to $pub_to_port\n";

    my @w;
    #my $zmq_pull_sock={};


        my $zmq_reply_sock= zmq_socket($ZMQ_CONTEXT, ZMQ_REP);

        my $connect_str = "tcp://*:$PI_RULES_DAEMON_SEND_PORT";
        print timestamp. "Listening to $connect_str\n";

        if ( my $zmq_state = zmq_connect($zmq_reply_sock, $connect_str )){
            croak "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
        };
        # get a non blocking file-handle from zmq:
        my $fh = zmq_getsockopt( $zmq_reply_sock, ZMQ_FD );


        push @w, anyevent_io( $fh, $zmq_reply_sock );


    push @w, AnyEvent->timer(
        after    => 0.1,
        interval => $PUBLISH_STATUS_EVERY_SECS,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;

}

sub anyevent_io {
    my ( $fh, $zmq_sock ) = @_;
    return AnyEvent->io(
        fh   => $fh,
        poll => "r",
        cb   => sub {
            while (
                my $recvmsg = zmq_recvmsg( $zmq_sock, ZMQ_RCVMORE )
            ){
                controller_message(zmq_msg_data($recvmsg));
            }
        },
    );
}

sub timer_cb {

    print "in timer ".time."\n";
    #zmq_sendmsg ( $zmq_publisher, "in the timer" );

}

sub controller_message {
    my ($msg) = @_ ;

    print "$msg\n";
    #my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;
    # ^^^ can't get $topic working in perl yet. TODO

    #zmq_sendmsg ( $zmq_publisher, "the status of whatever the control did" );

    my $msg_decoded;
    eval{$msg_decoded = $JSON->decode( $msg );};

    if ($@) {
        print "ERROR. JSON decode of message failed. \n$@\n";
        return;
    }

    my $epoch_time
        = $msg_decoded->{EpochTime};
    my $control_name
        = $msg_decoded->{Control};
    my $home_auto_class
        = $msg_decoded->{HomeAutoClass}; # Why do I need HomeAutoClass ? TODO probably deprecate this.
    my $action
        = $msg_decoded->{Action};

    print "\n".timestamp."Message received. '$control_name' '$action' \n";
    print Dumper($msg_decoded)."\n" if $VERBOSE;

    # TODO. All this error checking is already in Khaospy::Controls, either rely on that OR factor it out and put it in a common place so both bits of code can call it.

    if ( ! exists $controls_conf->{$control_name} ){
        print timestamp."ERROR control $control_name doesn't exist in the config\n";
        return;
    }
    my $control = $controls_conf->{$control_name} ;

    if ( ! exists $control->{host} ){
        print timestamp."ERROR control $control_name doesn't have a host configured\n";
        return;
    }

    if ( $control->{host} ne hostname ) {
        print timestamp."control $control_name is not controlled by this host\n";
        return;
    }

    if ( ! exists $control->{type} ){
        print timestamp."ERROR control $control_name doesn't have a type configured\n";
        return;
    }

    if ( $control->{type} eq 'pi-gpio-relay'){
        return operate_pi_gpio_relay($control_name,$control, $action);
    }

    print timestamp."ERROR control $control_name with type $control->{type} could be invalid. Or maybe it hasn't been programmed yet. Some are still TODO\n";
    return;

}



