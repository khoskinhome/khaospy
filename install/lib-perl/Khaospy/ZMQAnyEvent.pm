package Khaospy::ZMQAnyEvent;
use strict;
use warnings;

use Exporter qw/import/;
use Carp qw/croak/;

use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_SUBSCRIBE
    ZMQ_FD
    ZMQ_SUB  ZMQ_PUB
    ZMQ_PULL ZMQ_PUSH
    ZMQ_REQ  ZMQ_REP
);

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON
    true false
    ON OFF STATUS
);

use Khaospy::Log qw(
    klogfatal klogerror
    kloginfo  klogdebug
);

our @EXPORT_OK = qw( anyevent_zmq );

=head2

    params p => {
        connect   => string to connect to. COMPULSORY.
        zmq_type  => ZMQ_PUB  , ZMQ_SUB   COMPULSORY.
                     ZMQ_REQ  , ZMQ_REPLY
                     ZMQ_PUSH , ZMQ_PULL

        subscribe => 'channel'. defaults to ''

        msg_handler => \&sub_name or code-ref. COMPULSORY.
        msg_handler_param => scalar. Gets passed to msg_handler subroutine. OPTIONAL.

        klog   => true/false . default = false

        worker_ra => array_ref of AnyEvent-worker-array . COMPULSORY.
    }

    creates a zmq_socket of specified type.

    connect to zmq_socket.

    pushes an anyevent_io() to the anyevent-worker-array-ref


=cut

sub anyevent_zmq{
    my ($p) = @_;

    my $zmq_type = $p->{zmq_type};
    klogfatal "Need to supply a valid zmq_type"
        if ( ! $zmq_type
             || $zmq_type != ZMQ_SUB  || $zmq_type != ZMQ_PUB
             || $zmq_type != ZMQ_PULL || $zmq_type != ZMQ_PUSH
             || $zmq_type != ZMQ_REQ  || $zmq_type != ZMQ_REP );

    my $connect_str
        = $p->{connect}
            or klogfatal "Need to supply a 'connect' string";

    my $msg_handler = $p->{msg_handler};
    klogfatal "Need to supply a valid msg_handler\n"
        if ( !$msg_handler || ! ref $msg_handler eq 'CODE' );

    my $msg_handler_param = $p->{msg_handler_param};

    my $klog = defined $p->{klog} ? $p->{klog} : false ;

    my $worker_ra = $p->{worker_ra};
    klogfatal "Need to supply a valid worker-ra array-ref\n";

    my $zmq_sock = zmq_socket($ZMQ_CONTEXT, $zmq_type);

    if ( my $zmq_state = zmq_connect($zmq_sock, $connect_str )){
        klogfatal "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
    };

    kloginfo "Listening to $connect_str";

    my $fh = zmq_getsockopt( $zmq_sock, ZMQ_FD );
    zmq_setsockopt($zmq_sock, ZMQ_SUBSCRIBE, $p->{subscribe} || '');

    push @$worker_ra,
        anyevent_io(
            $fh,
            $zmq_sock,
            $msg_handler,
            $msg_handler_param
    );

}

sub anyevent_io {
    my ( $fh, $zmq_sock, $msg_handler, $msg_handler_param ) = @_;
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
