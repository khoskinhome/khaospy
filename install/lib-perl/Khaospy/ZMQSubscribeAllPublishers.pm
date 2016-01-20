package Khaospy::ZMQSubscribeAllPublishers;
use strict;
use warnings;

# used by CLI khaospy-zmq-subscribe.pl to listen to all publishers on a host.

use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use Sys::Hostname;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_FD
    ZMQ_SUB
    ZMQ_SUBSCRIBE
);

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use zhelpers;

use Khaospy::Constants qw(
    $JSON
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS

    $LOCALHOST

    $ONE_WIRE_DAEMON_PORT
    $PI_RULES_DAEMON_SEND_PORT
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT
    $PI_STATUS_DAEMON_SEND_PORT
    $MAC_SWITCH_DAEMON_PORT
    $PING_SWITCH_DAEMON_PORT
);

use Khaospy::Conf qw(
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
    DEBUG
);

use Khaospy::Utils qw( timestamp );

our @EXPORT_OK = qw( run_subscribe_all );

our $LOGLEVEL;

my $pi_controller_conf;

sub run_subscribe_all {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;
    $Khaospy::Log::OVERRIDE_CONF_LOGLEVEL = $opts->{"log-level"} || DEBUG;

    my $sub_host = $opts->{"host"} || $LOCALHOST;

    kloginfo "Subscribe all Publishers START";
    kloginfo "LOGLEVEL = ".$Khaospy::Log::OVERRIDE_CONF_LOGLEVEL;
    kloginfo "HOST     = ".$sub_host;

    my @subscribe_ports = get_ports($opts);

    kloginfo "Subscribing to ", \@subscribe_ports;

    my @w;

    for my $port ( @subscribe_ports ){

        my $zmq_sock= zmq_socket($ZMQ_CONTEXT, ZMQ_SUB);

        my $connect_str = "tcp://$sub_host:$port";
        kloginfo "Listening to $connect_str";

        if ( my $zmq_state = zmq_connect($zmq_sock, $connect_str )){
            croak "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
        };

#install/lib-perl/Khaospy/OneWireHeatingDaemon.pm:81:        zmq_setsockopt($subscriber, ZMQ_SUBSCRIBE, 'oneWireThermometer');

        my $fh = zmq_getsockopt( $zmq_sock, ZMQ_FD );
        zmq_setsockopt($zmq_sock, ZMQ_SUBSCRIBE, '');

        push @w, anyevent_io( $fh, $zmq_sock, $port );
    }

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub anyevent_io {
    my ( $fh, $zmq_sock, $port ) = @_;
    return AnyEvent->io(
        fh   => $fh,
        poll => "r",
        cb   => sub {
            while (
                my $recvmsg = zmq_recvmsg( $zmq_sock, ZMQ_RCVMORE )
            ){
                my $msg = zmq_msg_data($recvmsg);
                kloginfo "$port : $msg";

                #my $msg_decoded = $json->decode( $msgdata );
            }
        },
    );
}

sub get_ports {
    my ($opts) = @_;
    my @ports;

    push @ports, $ONE_WIRE_DAEMON_PORT
        if $opts->{"one-wire"};

    push @ports, $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
        if $opts->{"control-queue"};

    push @ports, $PI_CONTROLLER_DAEMON_SEND_PORT
        if $opts->{"control"};

    push @ports, $PI_STATUS_DAEMON_SEND_PORT
        if $opts->{"status"};

    push @ports, $MAC_SWITCH_DAEMON_PORT
        if $opts->{"mac"};

    push @ports, $PING_SWITCH_DAEMON_PORT
        if $opts->{"ping"};

    @ports = (
        $ONE_WIRE_DAEMON_PORT,
        $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT,
        $PI_CONTROLLER_DAEMON_SEND_PORT,
        $PI_STATUS_DAEMON_SEND_PORT,
        $MAC_SWITCH_DAEMON_PORT,
        $PING_SWITCH_DAEMON_PORT,
    ) if ! @ports;

    return @ports;
}

1;
