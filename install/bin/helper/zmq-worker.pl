#!/usr/bin/perl
=pod

Task worker

Connects PULL socket to tcp://localhost:5557

Collects workloads from ventilator via that socket

Connects PUSH socket to tcp://localhost:5558

Sends results to sink via that socket

Author: Daisuke Maki (lestrrat)
Author: Alexander D'Archangel (darksuji) <darksuji(at)gmail(dot)com>

=cut

use strict;
use warnings;
use 5.10.0;

use IO::Handle;

use Carp qw/croak/;

use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_PULL ZMQ_PUSH);
use English qw/-no_match_vars/;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../../lib-perl";
use Khaospy::Constants qw(
    true false
    ON OFF STATUS
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT
);

use zhelpers;

my $context = zmq_init();

# Socket to receive messages on
my $zmq_receiver = zmq_socket($context, ZMQ_PULL);

my $listen_to   = "pitest";
my $connect_str = "tcp://".$listen_to.":$PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT";
print "Listening to $connect_str\n";
if ( my $zmq_state = zmq_connect($zmq_receiver, $connect_str )){
    croak "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
};

print "connected to socket\n";

# Process tasks forever
print "process forever\n";
while (1) {
    my $string = zhelpers::s_recv($zmq_receiver);
    print $string."\n";
    # Simple progress indicator for the viewer
    STDOUT->printflush(".");

}

