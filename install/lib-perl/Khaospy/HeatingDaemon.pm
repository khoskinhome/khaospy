package Khaospy::HeatingDaemon;
use strict;
use warnings;

use Exporter qw/import/;

use Data::Dumper;
use Carp qw/croak/;
use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB);

# TODO . This will be deprecated with a rules based system.
# There will be no HEATING_DAEMON_CONF_FULLPATH
# There will be a rules daemons that can get the status of thermometer type controls,
# window-switch type controls and then issue commands to radiator-controllers.

use JSON;

use Khaospy::Utils qw(
    timestamp
    get_hashval
);

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS
    $HEATING_DAEMON_CONF_FULLPATH

    $ONE_WIRE_SENDER_PERL_SCRIPT
    $ONE_WIRE_DAEMON_PERL_PORT
);

use Khaospy::QueueCommand qw(
    queue_command
);

use Khaospy::Conf qw(
    get_one_wire_heating_control_conf
);

use Khaospy::Conf::PiHosts qw(
    get_pi_hosts_running_daemon
);

use Khaospy::Log qw(
    klogstart kloginfo klogfatal klogdebug klogerror klogwarn
);

use Khaospy::ZMQAnyEvent qw(
    zmq_anyevent
);

our @EXPORT_OK = qw(
    run_heating_daemon
);

my $json = JSON->new->allow_nonref;

use POSIX qw(strftime);

#############################################################
# getting the temperatures.
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html

sub run_heating_daemon {

    klogstart "Heating Daemon START";

    my $quit_program = AnyEvent->condvar;

    my @w = ();

    my $count_zmq_subs=0;
    # subscribe to all the hosts publishing one-wire thermometers.
    for my $sub_host (
        @{get_pi_hosts_running_daemon($ONE_WIRE_SENDER_PERL_SCRIPT)}
    ){
        $count_zmq_subs++;
        push @w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $ONE_WIRE_DAEMON_PERL_PORT,
            msg_handler       => \&process_thermometer_msg,
            msg_handler_param => "",
            klog              => true,
        });
    }

    croak "No One-Wire thermometer senders are configured. Heating-D Can't subscribe to anything."
        if ! $count_zmq_subs;

    $quit_program->recv;
}

{
    my $thermometer_conf;

    eval { $thermometer_conf = get_one_wire_heating_control_conf();};
    if ($@) {
        klogerror "Reading in the conf.";
        klogerror $@;
        klogfatal "Please check the conf file $HEATING_DAEMON_CONF_FULLPATH";
    }

    sub process_thermometer_msg {
        my ($zmq_sock, $msg, $param) = @_;

        my $msg_rh = $json->decode( $msg );

        my $control_name
            = get_hashval($msg_rh, 'control_name');
        my $owaddr
            = get_hashval($msg_rh, 'onewire_addr');
        my $current_value_temp
            = get_hashval($msg_rh, 'current_value');
        my $request_epoch_time
            = get_hashval($msg_rh, 'request_epoch_time');

        my $new_thermometer_conf ;
        eval { $new_thermometer_conf = get_one_wire_heating_control_conf();};
        if ($@ ) {
            klogerror "Getting the conf.";
            klogerror "Probably a broken conf $HEATING_DAEMON_CONF_FULLPATH";
            klogerror "$@";
            klogerror "Using the old conf";
        }
        $thermometer_conf = $new_thermometer_conf || $thermometer_conf ;

        my $tc   = $thermometer_conf->{$owaddr};

        klogwarn "One-wire address $owaddr isn't in "
            ."$HEATING_DAEMON_CONF_FULLPATH config file"
                if ! defined $tc ;

        my $name = $tc->{name} || '';
        klogerror "'name' isn't defined for one-wire address $owaddr in "
           ."$HEATING_DAEMON_CONF_FULLPATH "
                if ! $name ;

        my $operate_control_name = $tc->{control} || '';
        my $upper_temp   = $tc->{upper_temp} || '';

        if ( ! $operate_control_name && ! $upper_temp ){
            klogdebug "$name : $owaddr : $current_value_temp C";
            return ;
        }

        my $lower_temp = $tc->{lower_temp} || ( $upper_temp - 1 );

        if ( ! $operate_control_name || ! defined $upper_temp || ! defined $lower_temp ){
            klogerror "Not all the parameters are configured for this thermometer";
            klogerror "Both the 'upper_temp' and 'control' need to be defined";
            klogerror "upper_temp = $upper_temp C";
            klogerror "control    = '$operate_control_name'";
            klogerror "Please fix the config file $HEATING_DAEMON_CONF_FULLPATH";
            return;
        }

        if ( $upper_temp <= $lower_temp ){
            klogerror "Broken temperature range in $HEATING_DAEMON_CONF_FULLPATH config.";
            klogerror "(Upper) $upper_temp C <= $lower_temp C (Lower)";
            klogerror "Upper temperature must be greater than the lower temperature";
            klogerror "Please fix the config file $HEATING_DAEMON_CONF_FULLPATH";
            klogerror "Cannot operate this control.";
            return;
        }

        kloginfo "$name : $owaddr : $current_value_temp C : lower = $lower_temp C : upper = $upper_temp C";
        klogdebug "msg", $msg_rh;

        my $send_cmd = sub {
            my ( $action ) = @_;
            my $retval;
            kloginfo "Send command to '$operate_control_name' '$action'";
            eval { $retval = queue_command($operate_control_name, $action); };
            if ( $@ ) {
                klogerror "$@";
                return
            }
        };

        if ( $current_value_temp > $upper_temp ){
            $send_cmd->(OFF);
        }
        elsif ( $current_value_temp < $lower_temp ){
            $send_cmd->(ON);
        } else {
            kloginfo "Current temperate is in correct range\n";
        }
    }
}
1;
