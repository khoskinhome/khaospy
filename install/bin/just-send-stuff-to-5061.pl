#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use Time::HiRes qw/usleep/;

use Data::Dumper;
use Carp qw/croak/;
use JSON;

my $json = JSON->new->allow_nonref;

use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_PUB
    ZMQ_SNDHWM
);

#    ZMQ_SUB
#    ZMQ_SUBSCRIBE
#    ZMQ_RCVMORE
#    ZMQ_FD


my $context   = zmq_init();
my $publisher = zmq_socket($context, ZMQ_PUB);


#zmq_setsockopt( $publisher, ZMQ_SNDHWM, 2 );
print "get sock opt ZMQ_SNDHWM ".zmq_getsockopt( $publisher, ZMQ_SNDHWM )."\n";


my $pub_to_port = "tcp://*:5061";

#my $pub_to_port = "tcp://*:$PI_CONTROLLER_DAEMON_LISTEN_PORT";
zmq_bind( $publisher, $pub_to_port );

for my $z ( 1..10) {
    my $msg = $json->encode({
#      EpochTime     => time,
#      HomeAutoClass => 'PiController',
      cycle         => $z,
    });

    for my $blah ( 1.2 ) {
    #    sleep 1;
        if ( zmq_sendmsg( $publisher, "blah $msg" ) == -1 ){ print "Error $!\n"; };
        usleep 1000000;
        print "Sent to $pub_to_port : \n $msg\n";

    }

    sleep 2;
}

zmq_close($publisher);
