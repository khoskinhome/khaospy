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
    slurp
    get_one_wire_sender_hosts
    get_heating_controls_for_boiler
);

use Khaospy::Constants qw(
    true false
    ON OFF STATUS
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $ONE_WIRE_DAEMON_PORT
    $BOILER_DAEMON_PORT
    $BOILER_CONTROL_NAME
);

use Khaospy::Controls qw(
    send_command
);

use Khaospy::Conf qw(
    get_heating_thermometer_conf
);

my $json = JSON->new->allow_nonref;

my $heating_controls_for_boiler_status
    = { map { $_ => OFF } @{get_heating_controls_for_boiler()}};


#    get_heating_controls_not_for_boiler
#my $heating_controls_not_for_boiler_status
#    = { map { $_ => OFF } @{get_heating_controls_not_for_boiler()}};

use Getopt::Long;
my $verbose = false;
use POSIX qw(strftime);
GetOptions ( "verbose" => \$verbose );

print "#############\n";
print "Boiler Daemon\n";
print "Start time ".strftime("%F %T", gmtime(time) )."\n";
print "VERBOSE = ".($verbose ? "TRUE" : "FALSE")."\n";

#print "Controls for boiler :\n" if $verbose ;
print "boiler heating controls\n"
    .Dumper ( $heating_controls_for_boiler_status ) if $verbose;
#print "NOT boiler heating controls \n"
#    .Dumper ( $heating_controls_not_for_boiler_status ) if $verbose;

=pod

The boiler daemon will get the conf of all the heating controls that are associated with the boiler.

The the heating control script daemon will send the current state of the control to the boiler daemon.

When any of the rad-controls are on then the boiler will be switched on .

When all of the rad-controls are off the boiler will be switched off.

The boiler daemon will listenning (subscribes) on a zero-mq port for a json message in the format of :
    {
      EpochTime'     => '1451416995.77076',
      HomeAutoClass' => 'boilerControl',
      Control'       => 'a-control-name',
      Action         => 'on'
    };

If it receives a message for a control that is not associated to a radiator valve, it will just ignore it.
So the code in the heating-control-script doesn't have to think about "is this a boiler control ?"

If the boiler is in the off state, and one or more of the controls switches on, then due to the rad-actuators taking a couple of minutes to operate, the boiler-daemon will wait for $delay_boiler_off_to_on_secs before it switches on.

If all the rads go into the off state , the boiler will be switched off immediately. ( pump-over-run might be in operation on the boiler )

The heating-control-daemon publishes to the port that the boiler-daemon is listenning to.
It is easiet for the boiler-daemon to run on the same host as the heating-control-daemon.
Hence the heating-control-daemon can publish to localhost and the boiler-daemon can listen to localhost.
So no config necessary for the host where the boiler daemon has to subscribe to.

=cut

#############################################################
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html

my $quit_program = AnyEvent->condvar;

my $context = zmq_init();

my $subscriber = zmq_socket($context, ZMQ_SUB);

#my $zmq_state = zmq_connect($subscriber, "tcp://*:$BOILER_DAEMON_PORT");

# TODO $HEATING_CONTROL_HOST needs to go in to Khaospy::Constants, if it is kept.
my $HEATING_CONTROL_HOST = 'localhost';
if ( my $zmq_state = zmq_connect($subscriber, "tcp://$HEATING_CONTROL_HOST:$BOILER_DAEMON_PORT" )){
    croak "zmq can't connect to tcp://$HEATING_CONTROL_HOST:$BOILER_DAEMON_PORT. status = $zmq_state . $!\n";
};


# '' is because I can't work out how to get the "topic" filter sent by Khaospy::Boiler.
zmq_setsockopt($subscriber, ZMQ_SUBSCRIBE, '' );

my $fh = zmq_getsockopt( $subscriber, ZMQ_FD );

my $w = anyevent_io( $fh, $subscriber );

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
                process_boiler_message ( zmq_msg_data($recvmsg) );
            }
        },
    );
}

sub process_boiler_message {
    my ($msg) = @_ ;
    #my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;
    # can't get $topic working in perl yet. TODO

    my $msg_decoded = $json->decode( $msg );

    print Dumper($msg_decoded)."\n" if $verbose;

    my $epoch_time
        = $msg_decoded->{EpochTime};
    my $control
        = $msg_decoded->{Control};
    my $home_auto_class
        = $msg_decoded->{HomeAutoClass}; # Why do I need HomeAutoClass ? TODO probably deprecate this.
    my $action
        = $msg_decoded->{Action};

    if ( ! exists $heating_controls_for_boiler_status->{$control} ){
        print "control '$control' is not a boiler fed radiator control\n";
        return;
    }

    $heating_controls_for_boiler_status->{$control} = $action;
    operate_boiler();

}

sub operate_boiler {
    # so if at least one of the heating controls that is tied to the boiler
    # is on then the boiler needs to be switched on.

    # if all the heating controls associated with the boiler are off
    # then the boiler can be switched off.

    print "    Boiler heating controls are \n" if $verbose;
    print Dumper ( $heating_controls_for_boiler_status ) if $verbose;

    if ( grep { $heating_controls_for_boiler_status->{$_} eq ON }
         keys %$heating_controls_for_boiler_status
    ){
        boiler_on();
    } else {
        boiler_off();
    }
}

#    boiler_on
#    boiler_off
#    boiler_status

my $last_off_time;
my $last_on_time;
my $delay_boiler_off_to_on_secs = 120 ;

my $boiler_status = ON;

sub boiler_on {
    print "TURN BOILER ON\n";
    $boiler_status = send_command( $BOILER_CONTROL_NAME , ON );
}
#
sub boiler_off {
    print "TURN BOILER OFF\n";
    $boiler_status = send_command( $BOILER_CONTROL_NAME , OFF );
}


#
#sub boiler_status {
#    $boiler_status = send_command( $BOILER_CONTROL_NAME , STATUS );
#    print "BOILER STATUS = $boiler_status\n";
#}
#


