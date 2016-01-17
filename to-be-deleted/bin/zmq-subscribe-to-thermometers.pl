#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;



############################
#/sys/bus/w1/devices/28-00000670596d/w1_slave  bathroom
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-00000670596d", "EpochTime": 1448811213.284851, "Celsius": 21.812}

#/sys/bus/w1/devices/28-0000066ebc74/w1_slave  alison
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-0000066ebc74", "EpochTime": 1448811214.115049, "Celsius": 20.562}

#/sys/bus/w1/devices/28-021463277cff/w1_slave  loft
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-021463277cff", "EpochTime": 1448811214.94498, "Celsius": 14.187}

#/sys/bus/w1/devices/28-021463423bff/w1_slave  landing
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-021463423bff", "EpochTime": 1448811215.774984, "Celsius": 20.062}

#/sys/bus/w1/devices/28-0214632d16ff/w1_slave  amelia
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-0214632d16ff", "EpochTime": 1448811216.615052, "Celsius": 20.812}
#

use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_POLLIN);

use JSON;

die "\$ZMQ_CONTEXT will need getting from Khaospy::Constants if this script is to ever be used again\n";
my $subscriber = zmq_socket($context, ZMQ_SUB);
zmq_connect($subscriber, 'tcp://localhost:5001');

my $topicfilter = "oneWireThermometer";
zmq_setsockopt($subscriber, ZMQ_SUBSCRIBE, $topicfilter);

my %stat;
my $cnt=0;


while (1) {
    zmq_poll([{
        socket  => $subscriber,
        events  => ZMQ_POLLIN,
        callback => sub {
            my $msg = zmq_msg_data(zmq_recvmsg($subscriber));
            $msg=~s/^request //;
            print "someone accessed $msg\n";

            $cnt++;
            $stat{ $msg }++;
            if ($cnt % 10 == 0 ) {
                foreach (sort keys %stat) {
                    say "$_\t$stat{$_}";
                }
            }
        }
    }]);
}
