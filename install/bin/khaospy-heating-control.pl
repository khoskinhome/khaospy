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

use Khaospy::Utils qw(
    slurp
    get_one_wire_sender_hosts
    get_controls_for_boiler
);

use Khaospy::Constants qw(
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
);

use Khaospy::Controls qw(
    send_command
);

use Khaospy::Conf qw(
    get_heating_thermometer_conf
);

my $json = JSON->new->allow_nonref;

my $controls_for_boiler_status
    = { map { $_ => "off" } @{get_controls_for_boiler()}};

print "Controls for boiler :\n";
print Dumper ( $controls_for_boiler_status );

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

    my $thermometer_conf = get_heating_thermometer_conf();
    my $tc   = $thermometer_conf->{$owaddr};

    if ( ! defined $tc ) {
        print "One-wire address $owaddr isn't in "
            ."$KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH config file\n";
        return;
    }

    my $name = $tc->{name}
        || die "name isn't defined for one-wire address $owaddr in "
            ."$KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH ";

    print "##\n";
    print "$name : $owaddr : $curr_temp C\n";

    my $control_name = $tc->{control} || '';
    my $upper_temp   = $tc->{upper_temp} || '';

    return if ( ! $control_name && ! $upper_temp );

    my $lower_temp = $tc->{lower_temp} || ( $upper_temp - 1 );

    if ( ! $control_name || ! $upper_temp || ! $lower_temp ){
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

    my $send_cmd = sub {
        my ( $action ) = @_;
        my $retval;
        eval { $retval = send_command($control_name, $action); };
        if ( $@ ) { print "$@\n" }
        else {
            # TODO what if retval ne $action ? what am I gonna do ?
            # blow up , just log it ..... dunno.
            print "   control status '$retval'\n";

            if ( exists $controls_for_boiler_status->{$control_name} ){
                $controls_for_boiler_status->{$control_name} = $retval;
                operate_boiler();
            }
        };
    };

    if ( $curr_temp > $upper_temp ){
        print "    control : $control_name off : (Current) $curr_temp > (Upper) $upper_temp\n";
        $send_cmd->("off");
    }
    elsif ( $curr_temp < $lower_temp ){
        print "    control : $control_name on : (Current) $curr_temp < (Lower) $lower_temp\n";
        $send_cmd->("on");
    } else {
        print "    Current temperate is in correct range : (Lower) $lower_temp < (Current) $curr_temp < (Upper) $upper_temp\n";
        $send_cmd->("status");
    }
}

sub operate_boiler {
    if ( grep { $controls_for_boiler_status->{$_} eq 'on' }
         keys %$controls_for_boiler_status
    ){
        #TODO the actuators take about 2 mins to operate,
        # Do i need a configurable time to pause send the "ON"
        # signal to the boiler ?
        # Otherwise the boiler will be pushing hot water to a rad that is not on.
        # This delay would only be valid when changing state from
        # "OFF" to "ON".
        # If the boiler is already on ( because a rad valve is open )
        # then a 2 min delay isn't necessary.

         print " TURN BOILER ON\n";
        # TODO actaully get this to run some code .
        # I could use an orviboS20 for testing.

    } else {
         print " TURN BOILER OFF\n";
    }
    print Dumper ( $controls_for_boiler_status );
}


