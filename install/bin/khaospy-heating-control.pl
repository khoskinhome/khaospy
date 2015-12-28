#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_RCVMORE ZMQ_FD);

use JSON;
use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw/
    slurp
    get_one_wire_sender_hosts
/;

use Khaospy::OrviboS20 qw/signal_control/;

use Khaospy::Constants qw(
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $KHAOSPY_ORVIBO_S20_CONF_FULLPATH
);

# generate the daemon-runner JSON conf file in perl !

my $json = JSON->new->allow_nonref;

# 2015-12-25 . This is the current script for polling thermometers and switching the heating on/off . currently just by "orvibo S20"s wifi sockets.

my $thermometer_conf = $json->decode(
    slurp ( $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH )
);

  ## install/bin/khaospy-generate-rrd-graphs.pl:21:my $thermometer_conf = $json->decode( # TODO rm this line

  ## install/lib-perl/Khaospy/Constants.pm:113:        '28-0000066ebc74' => { # TODO rm this line

my $controls = $json->decode(
    slurp ( $KHAOSPY_ORVIBO_S20_CONF_FULLPATH )
);

#############################################################
# getting the temperatures.
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html

my $quit_program = AnyEvent->condvar;

my $context = zmq_init();

my $w = [];

for my $host ( get_one_wire_sender_hosts() ) {
    print "Listening to host $host\n";

    my $subscriber = zmq_socket($context, ZMQ_SUB);
    zmq_connect($subscriber, "tcp://$host:5001");
    zmq_setsockopt($subscriber, ZMQ_SUBSCRIBE, 'oneWireThermometer');

    my $fh = zmq_getsockopt( $subscriber, ZMQ_FD );

    push @$w , anyevent_io( $fh, $subscriber);
};

$quit_program->recv;

######################################################


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

    my $owaddr    = $msg_decoded->{OneWireAddress};
    my $curr_temp = $msg_decoded->{Celsius};

    my $tc   = $thermometer_conf->{$owaddr};

    if ( ! defined $tc ) {
        print "One-wire address $owaddr isn't in "
            ."$KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH config file\n";
        return;
    }

    my $name = $tc->{name}
        || die "name isn't defined for one-wire address $owaddr in "
            ."$KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH ";

    print "##########\n";
    print "$name : $owaddr : Celsius = $curr_temp.\n";

    my $turn_on_command    = $tc->{turn_on_command} || '';
    my $turn_off_command   = $tc->{turn_off_command} || '';
    my $get_status_command = $tc->{get_status_command} || '';
    my $upper_temp         = $tc->{upper_temp} || '';
    my $lower_temp         = $tc->{lower_temp} || '';

    if ( ! $turn_on_command && ! $turn_off_command && ! $get_status_command
        && ! $upper_temp && ! $lower_temp
    ){
        print "    Nothing configured for this thermometer\n";
        return;
    }

    if ( ! $turn_on_command || ! $turn_off_command || ! $get_status_command
        || ! $upper_temp || ! $lower_temp
    ){
        print "    Not all the parameters are configured for this thermometer\n";
        print "    See the config file $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH\n";
        print "    Cannot operate this control.\n";
        return;
    }

    if ( $upper_temp <= $lower_temp ) {
        print "    Broken temperature range in $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH config.\n";
        print "    (Upper) $upper_temp <= (Lower) $lower_temp\n";
        print "    Upper temperature must be greater than the lower temperature\n";
        return;
    }

    if ( $curr_temp > $upper_temp ){
        print "    turn_off_command : ".$turn_off_command." : (Current) $curr_temp > (Upper) $upper_temp\n";

    }
    elsif ( $curr_temp < $lower_temp ){
        print "    turn_on_command : ".$turn_on_command." : (Current) $curr_temp < (Lower) $lower_temp\n";


    } else {
        print "    Current temperate is in correct range : (Lower) $lower_temp < (Current) $curr_temp < (Upper) $upper_temp\n";
    }

# TODO get the dispatching to an orviboS20 command working.
# TODO get the dispatching to the i2c connected rad-controllers.
#
#        if ( $hc->{orviboS20_rad_hostname} ) {
#            print "$name : Switch off ".$hc->{orviboS20_rad_hostname}."\n";
#            print "$name : signal_control = ".signal_control($hc->{orviboS20_rad_hostname},"off")."\n";
#        } else {
#            print "$name : Nothing configured to switch off\n";
#        }
#
#        if ( $hc->{orviboS20_rad_hostname} ) {
#            print "$name : Switch on ".$hc->{orviboS20_rad_hostname}."\n";
#            print "$name : signal_control = ".signal_control($hc->{orviboS20_rad_hostname},"on")."\n";
#        } else {
#            print "$name : Nothing configured to switch on\n";
#        }

}
