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


use Khaospy::Constants qw(
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
);

use Khaospy::Controls qw(
    send_command
);

my $json = JSON->new->allow_nonref;

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

    my $thermometer_conf = get_thermometer_conf();
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

    my $control            = $tc->{control} || '';
    my $upper_temp         = $tc->{upper_temp} || '';
    my $lower_temp         = $tc->{lower_temp} || '';

    if ( ! $control && ! $upper_temp && ! $lower_temp ){
        print "    Nothing configured for this thermometer\n";
        return;
    }

    if ( ! $control || ! $upper_temp || ! $lower_temp ){
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
        print "    control : $control off : (Current) $curr_temp > (Upper) $upper_temp\n";
        my $retval;
        eval { $retval = send_command($control, "off"); };
        if ( $@ ) { print "$@\n" }
        else { print "   control returned '$retval'" };

    }
    elsif ( $curr_temp < $lower_temp ){
        print "    control : $control on : (Current) $curr_temp < (Lower) $lower_temp\n";
        my $retval;
        eval { $retval = send_command($control, "on"); };
        if ( $@ ) { print "$@\n" }
        else { print "   control returned '$retval'" };
    } else {
        print "    Current temperate is in correct range : (Lower) $lower_temp < (Current) $curr_temp < (Upper) $upper_temp\n";
    }
}

{
    # TODO there should be a Khaospy::Conf for this sort of stuff.
    my $therm_conf;
    my $therm_conf_last_loaded;

    sub get_thermometer_conf {
        # reload the thermometer conf every 5 mins.
        if ( ! $therm_conf
            or $therm_conf_last_loaded + 20 < time  # TODO FIX THIS BACK TO 300 SECONDS.
        ) {
            $therm_conf = $json->decode(
                 slurp( $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH )
            );
            $therm_conf_last_loaded = time ;
        }

        return $therm_conf;
    }
}


