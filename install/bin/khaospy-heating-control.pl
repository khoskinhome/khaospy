#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Carp qw/croak/;
use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_RCVMORE ZMQ_FD);

use JSON;
use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw(
    get_one_wire_sender_hosts
);

use Khaospy::Constants qw(
    true false
    ON OFF STATUS
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $ONE_WIRE_DAEMON_PORT
);

use Khaospy::Controls qw(
    send_command
);

use Khaospy::Conf qw(
    get_heating_thermometer_conf
);

use Khaospy::BoilerMessage qw(
    send_boiler_control_message
);

my $json = JSON->new->allow_nonref;


use Getopt::Long;
my $verbose = false;
my $port = $ONE_WIRE_DAEMON_PORT;

use POSIX qw(strftime);
GetOptions ( "verbose" => \$verbose );

print "######################\n";
print "Heating control Daemon\n";
print "Start time ".strftime("%F %T", gmtime(time) )."\n";
print "VERBOSE = ".($verbose ? "TRUE" : "FALSE")."\n";

#############################################################
# getting the temperatures.
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html

my $quit_program = AnyEvent->condvar;

my $context = zmq_init();

my $w = [];

for my $host ( get_one_wire_sender_hosts() ) {
    print "Listening to Thermometers on host $host\n";

    my $subscriber = zmq_socket($context, ZMQ_SUB);

    zmq_connect($subscriber, "tcp://$host:$port");
    zmq_setsockopt($subscriber, ZMQ_SUBSCRIBE, 'oneWireThermometer');

    my $fh = zmq_getsockopt( $subscriber, ZMQ_FD );

    push @$w , anyevent_io( $fh, $subscriber);
};

$quit_program->recv;

exit 0;

#######
# subs

sub anyevent_io {
    my ( $fh, $subscriber ) = @_;
    return AnyEvent->io(
        fh   => $fh,
        poll => "r",
        cb   => sub {
            while ( my $recvmsg = zmq_recvmsg( $subscriber, ZMQ_RCVMORE ) ) {
                process_thermometer_msg ( zmq_msg_data($recvmsg) );
            }
        },
    );
}

sub process_thermometer_msg {
    my ($msg) = @_;
    my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;

    my $msg_decoded = $json->decode( $msgdata );

    # print Dumper($msg_decoded)."\n" if $verbose;

    my $owaddr    = $msg_decoded->{OneWireAddress};
    my $curr_temp = $msg_decoded->{Celsius};

    my $thermometer_conf = get_heating_thermometer_conf();
    my $tc   = $thermometer_conf->{$owaddr};

    print "One-wire address $owaddr isn't in "
        ."$KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH config file\n"
            if ! defined $tc ;
;
    my $name = $tc->{name} || '';
    print "'name' isn't defined for one-wire address $owaddr in "
       ."$KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH "
            if ! $name ;

    my $control_name = $tc->{control} || '';
    my $upper_temp   = $tc->{upper_temp} || '';

    if ( ! $control_name && ! $upper_temp ){
        print "$name : $owaddr : $curr_temp C\n" if $verbose;
        return ;
    }

    my $lower_temp = $tc->{lower_temp} || ( $upper_temp - 1 );

    print "#####\n";
    print "$name : $owaddr : $curr_temp C ";

    if ( ! $control_name || ! $upper_temp || ! $lower_temp ){
        print "\n    Not all the parameters are configured for this thermometer\n";
        print "    Both the 'upper_temp' and 'control' need to be defined\n";
        print "        upper_temp = $upper_temp\n";
        print "        control    = $control_name\n";
        print "    Please fix the config file $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH\n";
        print "    Cannot operate this control.\n";
        print "#####\n";
        return;
    }

    if ( $upper_temp <= $lower_temp ){
        print "\n    Broken temperature range in $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH config.\n";
        print "        (Upper) $upper_temp <= (Lower) $lower_temp\n";
        print "    Upper temperature must be greater than the lower temperature\n";
        print "    Please fix the config file $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH\n";
        print "    Cannot operate this control.\n";
        print "#####\n";
        return;
    }

    print " : lower = $lower_temp C : upper = $upper_temp C\n";

    my $send_cmd = sub {
        my ( $action ) = @_;
        my $retval;
        print "    Send command to '$control_name' '$action' \n";
        eval { $retval = send_command($control_name, $action); };
        if ( $@ ) {
            print "$@\n";
            return
        }

        if ( $retval ne $action and $action ne STATUS ){
            # Should this croak ? dunno....
            print "    ERROR. control returned value '$retval' NOT the action '$action'\n";
            return;
        }
        print "    Control '$control_name' is '$retval'\n";
        send_boiler_control_message($control_name, $retval)
            if $action ne STATUS ;
    };

    if ( $curr_temp > $upper_temp ){
        $send_cmd->(OFF);
    }
    elsif ( $curr_temp < $lower_temp ){
        $send_cmd->(ON);
    } else {
        print "    Current temperate is in correct range\n";
        $send_cmd->(STATUS);
    }
    print "#####\n";
}

