package Khaospy::ZMQAnyEvent;
use strict;
use warnings;

use Exporter qw/import/;
use Carp qw/croak/;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_SUBSCRIBE
    ZMQ_FD
    ZMQ_SUB
    ZMQ_PULL
    ZMQ_REP
);

use Khaospy::Conf::PiHosts qw/
    get_pi_hosts_running_daemon
/;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false

    $PI_CONTROLLER_DAEMON_SCRIPT
    $PI_CONTROLLER_DAEMON_SEND_PORT
    $OTHER_CONTROLS_DAEMON_SCRIPT
    $OTHER_CONTROLS_DAEMON_SEND_PORT
);

use Khaospy::Log qw(
    klogfatal klogerror
    kloginfo  klogdebug
);

use Khaospy::Utils qw(
    get_hashval
);

our @EXPORT_OK = qw(
    subscribe_to_controller_daemons
    zmq_anyevent
);

=head2

    params p => {
        host => Host. COMPULSORY.
        port => Port. COMPULSORY.
        zmq_type  => ZMQ_SUB or ZMQ_REP or ZMQ_PULL. COMPULSORY.

        subscribe => 'channel'. defaults to ''

        bind => true/false. OPTIONAL. defaults to false if not supplied.

        msg_handler => \&sub_name or code-ref. COMPULSORY.
        msg_handler_param => scalar. Gets passed to msg_handler subroutine. OPTIONAL.

        klog   => true/false . default = false
    }

    creates a zmq_socket of specified type.

    connects ( or binds ) to zmq_socket.

    returns the AnyEvent->io() that needs to be held in a @worker / $worker variable.

    the msg_handler will get called like so :

        $msg_handler->($zmq_sock, zmq_msg_data($recvmsg), $msg_handler_param);

=cut

sub zmq_anyevent{
    my ($p) = @_;

    my $zmq_type = $p->{zmq_type};
    klogfatal "Need to supply a valid zmq_type '$zmq_type'"
        if ( ! $zmq_type
             || ( $zmq_type != ZMQ_SUB
               && $zmq_type != ZMQ_PULL
               && $zmq_type != ZMQ_REP
             )
        );

    my $host = $p->{host}
        or klogfatal "Need to supply a 'host'";

    my $port = $p->{port}
        or klogfatal "Need to supply a 'port'";

    # Do i need to have (tcp) protocol parameterised ?
    my $connect_str = "tcp://$host:$port";

    my $msg_handler = $p->{msg_handler};
    klogfatal "Need to supply a valid msg_handler\n"
        if ( !$msg_handler || ! ref $msg_handler eq 'CODE' );

    my $msg_handler_param = $p->{msg_handler_param};

    my $klog = defined $p->{klog} ? $p->{klog} : false ;

    my $zmq_sock = zmq_socket($ZMQ_CONTEXT, $zmq_type);

    if ( exists $p->{bind} && $p->{bind} ){ # defaults to zmq_connect.
        if ( my $zmq_state = zmq_bind($zmq_sock, $connect_str )){
            # zmq_connect returns zero on success.
            klogfatal "zmq can't bind to $connect_str. status = $zmq_state . $!\n";
        };
    } else {
        if ( my $zmq_state = zmq_connect($zmq_sock, $connect_str )){
            # zmq_connect returns zero on success.
            klogfatal "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
        };
    }

    kloginfo "Listening to $connect_str";

    my $fh = zmq_getsockopt( $zmq_sock, ZMQ_FD );
    zmq_setsockopt($zmq_sock, ZMQ_SUBSCRIBE, $p->{subscribe} || '');

    return AnyEvent->io(
        fh   => $fh,
        poll => "r",
        cb   => sub {
            while (
                my $recvmsg = zmq_recvmsg( $zmq_sock, ZMQ_RCVMORE )
            ){
                $msg_handler->($zmq_sock, zmq_msg_data($recvmsg), $msg_handler_param);
            }
        },
    );
}

sub subscribe_to_controller_daemons {
    my ( $w, $p ) = @_;

    my $klog = exists $p->{klog} && defined $p->{klog} ? $p->{klog} : true;

    my $count_zmq_subs = 0;

    # Listen for the Pi Control Daemons return messages.
    for my $sub_host (
        @{get_pi_hosts_running_daemon(
            $PI_CONTROLLER_DAEMON_SCRIPT
        )}
    ){
        $count_zmq_subs++;
        push @$w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $PI_CONTROLLER_DAEMON_SEND_PORT,
            msg_handler       => get_hashval($p, 'msg_handler'),
            msg_handler_param => $p->{msg_handler_param} || "",
            klog              => $klog,
        });
    }

    # Listen for the other controls daemon.
    for my $sub_host (
        @{get_pi_hosts_running_daemon( $OTHER_CONTROLS_DAEMON_SCRIPT)}
    ){
        $count_zmq_subs++;
        push @$w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $OTHER_CONTROLS_DAEMON_SEND_PORT,
            msg_handler       => get_hashval($p, 'msg_handler'),
            msg_handler_param => $p->{msg_handler_param} || "",
            klog              => $klog,
        });
    }

    klogfatal "No Control Daemons configured. Can't subscribe to anything."
        if ! $count_zmq_subs;

}

1;
