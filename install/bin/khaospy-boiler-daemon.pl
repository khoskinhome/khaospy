#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Carp qw/croak/;
use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_RCVMORE ZMQ_FD);

use Clone 'clone';

use JSON;
use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw(
);

use Khaospy::Constants qw(
    true false
    ON OFF STATUS
    $HEATING_CONTROL_DAEMON_PUBLISH_PORT
);

use Khaospy::Controls qw(
    send_command
);

use Khaospy::Conf qw(
    get_boiler_conf
);

my $json = JSON->new->allow_nonref;


use Getopt::Long;
my $verbose = false;
use POSIX qw(strftime);
GetOptions ( "verbose" => \$verbose );

print "#############\n";
print "Boiler Daemon\n";
print "Start time ".strftime("%F %T", gmtime(time) )."\n";
print "VERBOSE = ".($verbose ? "TRUE" : "FALSE")."\n";

my $boiler_status;
init_boiler_status();

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

# TODO this needs to be worked out from looking at the daemon-runner conf.
# working out the host that the heating-control is running on.
# currently this hard coding means the boiler-daemon has to run on the same host as the heating-control-daemon.
my $HEATING_CONTROL_HOST = 'localhost';

my $connect_str = "tcp://$HEATING_CONTROL_HOST:$HEATING_CONTROL_DAEMON_PUBLISH_PORT";

if ( my $zmq_state = zmq_connect($subscriber, $connect_str )){
    croak "zmq can't connect to $connect_str. status = $zmq_state . $!\n";
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

#    $heating_controls_for_boiler_status->{$control} = $action;
    operate_boiler();

}

sub operate_boiler {
}

#    boiler_on
#    boiler_off
#    boiler_status

#sub boiler_on {
##    my ($boiler_control
#    print "TURN BOILER ON\n";
#
#    # TODO get the delay_boiler_off_to_on_secs working.
#
##    $boiler_status = send_command( $boiler_control_name , ON );
#}
##
#sub boiler_off {
#    print "TURN BOILER OFF\n";
##    $boiler_status = send_command( $boiler_control_name , OFF );
#}
#
##
#sub boiler   _status {
##    $boiler_status = send_command( $boiler_control_name , STATUS );
##    print "BOILER STATUS = $boiler_status\n";
#}


#sub map_boiler_control_status {
#
##$VAR1 = {
##          'frontroomrad' => {
##                              'on_delay_secs' => 120,
##                              'controls' => [
##                                              'alisonrad',
##                                              'karlrad',
##                                              'ameliarad',
##                                              'dinningroomrad'
##                                            ]
##                            }
##        };
#
#=pod
#    I am going to receive a control, I need to check this control against the boiler confs.
#
#    read in the conf .
#    make a local copy, changing the controls arrays to hashes that point to control.status
#    get the current control.status
#
#=cut
#
#}

sub init_boiler_status {
    # clone the boiler_conf in boiler_status,
    # and get the "controls" to be a hash that holds the "controls" state.

    my $boiler_conf = get_boiler_conf();

    print "Boiler-conf :\n".Dumper ( $boiler_conf ) if $verbose ;

    $boiler_status = clone($boiler_conf);

    for my $boiler_control ( keys %$boiler_conf ){
        my $b_stat =  $boiler_status->{$boiler_control};
        my $controls = { map { $_ => undef } @{$b_stat->{controls}} } ;
        $b_stat->{controls} = $controls;
        $b_stat->{current_status}  = undef;
        _sig_a_control ( $boiler_control, STATUS ,\$b_stat->{current_status} );

        $b_stat->{last_time_on}    = undef;
        $b_stat->{last_time_off}   = undef;

        $b_stat->{last_time_on}    = time
            if ( $b_stat->{current_status} eq ON ) ;

        $b_stat->{last_time_off}   = time
            if ( $b_stat->{current_status} eq OFF );
    };

    refresh_boiler_status();
}

sub refresh_boiler_status {
    # refresh the controls from directly signalling the control

    for my $boiler_control ( keys %$boiler_status){

        my $b_stat =  $boiler_status->{$boiler_control};
        my $controls = $b_stat->{controls};

        for my $control ( keys %$controls ) {
            _sig_a_control ( $control, STATUS, \$b_stat->{controls}{$control} );
        }
    };

    print "boiler-status = ".Dumper($boiler_status) if $verbose;
}

sub _sig_a_control {
    my ( $control, $action, $update_scalar_ref ) = @_;

    my $ret;
    eval { $ret = send_command( $control, STATUS ); };

    if ( $@ ) {
        print "Error signalling control '$control' with '$action'. $@\n";
        ${$update_scalar_ref} = undef ; # should this be OFF ?
    } else {
        ${$update_scalar_ref} = $ret;
    }
}

sub all_controls_on {


}
