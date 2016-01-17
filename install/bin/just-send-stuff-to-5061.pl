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
    ZMQ_PUSH
    ZMQ_SNDHWM
);

#    ZMQ_SUB
#    ZMQ_SUBSCRIBE
#    ZMQ_RCVMORE
#    ZMQ_FD

use Khaospy::Constants qw( $ZMQ_CONTEXT );

my $sender  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUSH);

#zmq_setsockopt( $sender, ZMQ_SNDHWM, 2 );
print "get sock opt ZMQ_SNDHWM ".zmq_getsockopt( $sender, ZMQ_SNDHWM )."\n";

my $send_to_port = "tcp://localhost:5061";

my $msg = "tadah !";

zmq_bind( $sender, $send_to_port );
print "Sending to $send_to_port : \n $msg\n";
if ( zmq_sendmsg( $sender, "$msg" ) == -1 ){ print "Error $!\n"; };

zmq_close($sender);

#sub cycle {
#    for my $z ( 1..10) {
#        my $msg = $json->encode({
#          cycle         => $z,
#        });
#
#        for my $blah ( 1.2 ) {
#        #    sleep 1;
#            print "Sending to $send_to_port : \n $msg\n";
#            if ( zmq_sendmsg( $sender, "$msg" ) == -1 ){ print "Error $!\n"; };
#            usleep 100000;
#            print "Sent to $send_to_port : \n $msg\n";
#
#        }
#
#        sleep 2;
#    }
#}
