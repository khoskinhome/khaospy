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

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
);

use Khaospy::Log qw(
    klogfatal klogerror
    kloginfo  klogdebug
);

our @EXPORT_OK = qw( zmq_anyevent );

=head2

    params p => {
        host => Host. COMPULSORY.
        port => Port. COMPULSORY.
        zmq_type  => ZMQ_SUB or ZMQ_REP or ZMQ_PULL. COMPULSORY.

        subscribe => 'channel'. defaults to ''

        msg_handler => \&sub_name or code-ref. COMPULSORY.
        msg_handler_param => scalar. Gets passed to msg_handler subroutine. OPTIONAL.

        klog   => true/false . default = false
    }

    creates a zmq_socket of specified type.

    connects to zmq_socket.

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

    my $host
        = $p->{host}
            or klogfatal "Need to supply a 'host'";

    my $port
        = $p->{port}
            or klogfatal "Need to supply a 'port'";

    # do i need to have tcp protocol parameterised ?
    my $connect_str = "tcp://$host:$port";

    my $msg_handler = $p->{msg_handler};
    klogfatal "Need to supply a valid msg_handler\n"
        if ( !$msg_handler || ! ref $msg_handler eq 'CODE' );

    my $msg_handler_param = $p->{msg_handler_param};

    my $klog = defined $p->{klog} ? $p->{klog} : false ;

    my $zmq_sock = zmq_socket($ZMQ_CONTEXT, $zmq_type);

    if ( my $zmq_state = zmq_connect($zmq_sock, $connect_str )){
        klogfatal "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
    };

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

1;
