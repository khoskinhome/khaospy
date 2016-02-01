package Khaospy::OneWireHeatingDaemon;
use strict;
use warnings;

use Exporter qw/import/;

use Data::Dumper;
use Carp qw/croak/;
use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_RCVMORE ZMQ_FD);

# TODO . This will be deprecated with a rules based system.
# There will be no KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
# There will be a rules daemons that can get the status of thermometer type controls,
# window-switch type controls and then issue commands to radiator-controllers.

use JSON;

use Khaospy::Utils qw(
    get_one_wire_sender_hosts
    timestamp
);

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
    $ONE_WIRE_DAEMON_PORT
);

use Khaospy::OperateControls qw(
    signal_control
);

use Khaospy::Conf qw(
    get_one_wire_heating_control_conf
);

use Khaospy::BoilerMessage qw(
    send_boiler_control_message
);

our @EXPORT_OK = qw(
    run_one_wire_heating_daemon
);

my $json = JSON->new->allow_nonref;

my $VERBOSE;

use POSIX qw(strftime);

#############################################################
# getting the temperatures.
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html

sub run_one_wire_heating_daemon {

    my ( $opts ) = @_;

    $opts = {} if ! $opts;

    $VERBOSE = $opts->{verbose} || false;

    print "######################\n";
    print timestamp."One-Wire Heating Control Daemon START\n";
    print timestamp."VERBOSE = ".($VERBOSE ? "TRUE" : "FALSE")."\n";

    my $quit_program = AnyEvent->condvar;


    my $w = [];

    for my $host ( get_one_wire_sender_hosts() ) {
        print timestamp."Listening to One-Wire Thermometers on host $host:$ONE_WIRE_DAEMON_PORT\n";

        my $subscriber = zmq_socket($ZMQ_CONTEXT, ZMQ_SUB);

        zmq_connect($subscriber, "tcp://$host:$ONE_WIRE_DAEMON_PORT");
        zmq_setsockopt($subscriber, ZMQ_SUBSCRIBE, 'oneWireThermometer');

        my $fh = zmq_getsockopt( $subscriber, ZMQ_FD );

        push @$w , anyevent_io( $fh, $subscriber);
    };

    $quit_program->recv;

}

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
{

    my $thermometer_conf;

    eval { $thermometer_conf = get_one_wire_heating_control_conf();};
    if ($@) {
        print "ERROR. Reading in the conf.\n$@\n";
        croak "ERROR. Please check the conf file $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH\n";
    }

    sub process_thermometer_msg {
        my ($msg) = @_;
        my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;

        my $msg_decoded = $json->decode( $msgdata );

        my $owaddr    = $msg_decoded->{OneWireAddress};
        my $curr_temp = $msg_decoded->{Celsius};

        my $new_thermometer_conf ;
        eval { $new_thermometer_conf = get_one_wire_heating_control_conf();};
        if ($@ ) {
            print "\n\nERROR. getting the conf.\n";
            print "ERROR. Probably a broken conf $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH\n";
            print "ERROR. $@";
            print "ERROR. Using the old conf\n\n";
        }
        $thermometer_conf = $new_thermometer_conf || $thermometer_conf ;

        my $tc   = $thermometer_conf->{$owaddr};

        print "ERROR. One-wire address $owaddr isn't in "
            ."$KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH config file\n"
                if ! defined $tc ;

        my $name = $tc->{name} || '';
        print "ERROR. 'name' isn't defined for one-wire address $owaddr in "
           ."$KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH "
                if ! $name ;

        my $control_name = $tc->{control} || '';
        my $upper_temp   = $tc->{upper_temp} || '';

        if ( ! $control_name && ! $upper_temp ){
            print "\n".timestamp."$name : $owaddr : $curr_temp C\n" if $VERBOSE;
            print Dumper($msg_decoded) if $VERBOSE;
            return ;
        }

        my $lower_temp = $tc->{lower_temp} || ( $upper_temp - 1 );

        print "\n".timestamp."$name : $owaddr : $curr_temp C ";

        if ( ! $control_name || ! defined $upper_temp || ! defined $lower_temp ){
            print "\nERROR. Not all the parameters are configured for this thermometer\n";
            print "ERROR. Both the 'upper_temp' and 'control' need to be defined\n";
            print "ERROR. upper_temp = $upper_temp C\n";
            print "ERROR. control    = '$control_name' \n";
            print "ERROR. Please fix the config file $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH\n";
            print "ERROR. Cannot operate this control.\n";
            return;
        }

        if ( $upper_temp <= $lower_temp ){
            print "\nERROR. Broken temperature range in $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH config.\n";
            print "ERROR. (Upper) $upper_temp C <= $lower_temp C (Lower)\n";
            print "ERROR. Upper temperature must be greater than the lower temperature\n";
            print "ERROR. Please fix the config file $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH\n";
            print "ERROR. Cannot operate this control.\n";
            return;
        }

        print " : lower = $lower_temp C : upper = $upper_temp C\n";
        print Dumper($msg_decoded) if $VERBOSE;

        my $send_cmd = sub {
            my ( $action ) = @_;
            my $retval;
            print timestamp."Send command to '$control_name' '$action' \n";
            eval { $retval = signal_control($control_name, $action); };
            if ( $@ ) {
                print "$@\n";
                return
            }

            if ( $retval ne $action and $action ne STATUS ){
                # Should this croak ? dunno....
                print timestamp."ERROR. control returned value '$retval' NOT the action '$action'\n";
                return;
            }
            print timestamp."Control '$control_name' is '$retval'\n" if $VERBOSE;
            send_boiler_control_message($control_name, $retval);
        };

        if ( $curr_temp > $upper_temp ){
            $send_cmd->(OFF);
        }
        elsif ( $curr_temp < $lower_temp ){
            $send_cmd->(ON);
        } else {
            print timestamp."Current temperate is in correct range\n";
            $send_cmd->(STATUS);
        }
    }
}
1;
