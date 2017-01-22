package Khaospy::RulesD;
use strict;
use warnings;

use Exporter qw/import/;

use Data::Dumper;
use Carp qw/croak/;
use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB);

use JSON;

use Khaospy::Utils qw(
    timestamp
    get_hashval
);

use Khaospy::Conf::Controls qw(
    state_to_binary
);

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS

    RULESD $RULESD

    $RULES_DAEMON_TIMER
    $TIMER_AFTER_COMMON

    $SCRIPT_TO_PORT
);

use Khaospy::QueueCommand qw(
    queue_command
);

use Khaospy::Conf qw(
    get_rulesd_conf
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

use Khaospy::DBH::Controls qw(
    get_last_control_state
    init_last_control_state
);

our @EXPORT_OK = qw(
    run_rules_daemon
);

my $json = JSON->new->allow_nonref;

use POSIX qw(strftime);

my $last_control_state = {};

my $window_sensor_to_control_name_map = {};

my $rules_conf;

sub run_rules_daemon {

    klogstart "Rules Daemon START";

    $last_control_state = get_last_control_state();

    kloginfo "dumper of lcs ",$last_control_state;

    my $quit_program = AnyEvent->condvar;

    $rules_conf = get_rulesd_conf();

    kloginfo "dumper of rules ", $rules_conf;

    my @w = ();

    for my $script ( keys %$SCRIPT_TO_PORT ){
        my $port = get_hashval($SCRIPT_TO_PORT, $script);
        for my $sub_host (
            @{get_pi_hosts_running_daemon($script)}
        ){
            kloginfo "Subscribing to $sub_host : $script : $port";
            push @w, zmq_anyevent({
                zmq_type          => ZMQ_SUB,
                host              => $sub_host,
                port              => $port,
                msg_handler       => \&process_msg,
                msg_handler_param => $port,
                klog              => true,
            });
        }
    }

    push @w, AnyEvent->timer(
        after    => $TIMER_AFTER_COMMON,
        interval => $RULES_DAEMON_TIMER,
        cb       => \&rules_check
    );

    $quit_program->recv;
}

sub send_cmd {
    my ( $operate_control_name, $action ) = @_;
    my $retval;
    kloginfo "Send command to '$operate_control_name' '$action'";
    eval { $retval = queue_command($operate_control_name, $action); };
    if ( $@ ) {
        klogerror "$@";
        return
    }
}

sub rules_check {
    kloginfo "checking the rules ...";

    for my $rule (@$rules_conf){
        try_rule($rule);
    }
}

sub ctl {
    my ($control_name) = @_;
    return get_hashval($last_control_state, $control_name)->{'current_state'};
}

sub ctl_val {
    my ($control_name) = @_;
    return get_hashval( get_hashval($last_control_state, $control_name), 'current_state');
}

sub try_rule {
    my ($rule) = @_;

    my $control_name = $rule->{control_name};
    my $rule_name    = $rule->{rule_name};
    my $action       = $rule->{action};
    kloginfo "running rule name $rule->{rule_name} on $control_name";
    my $ifs = $rule->{ifs};
    for my $if (@$ifs){
        my $action = $if->{action};
        my $iftest = $if->{if};
        my $do = false;

        my $evalstr = 'if ( '.$iftest.' ){ $do = true }';
        kloginfo "  $iftest";
        eval ( $evalstr );

        if ($@){
            kloginfo "error in rule $rule_name. $@";
            return;
        }
        if ($do) {
            kloginfo "    : matches $iftest\n    : do action '$action'" ;
            ## do_action($control_name, $action);
            return;
        }
    }
    kloginfo "    : no rule matches";
}

sub process_msg {
    my ($zmq_sock, $msg, $param) = @_;
    my $msg_rh = $json->decode( $msg );

    my $control_name = get_hashval($msg_rh, 'control_name');

    kloginfo "Received msg about $control_name";

    my $cst = $msg_rh->{current_state};

    if ( defined $cst ){
        my $curr_state_bin = state_to_binary($cst);

        kloginfo "Received msg about $control_name it is $curr_state_bin ";

        $last_control_state->{$control_name}{current_state}=$curr_state_bin;

    }
#
#        init_last_control_state($last_control_state, $control_name);
#        $last_control_state->{$control_name}{last_value} = $curr_state_bin;
#
#        kloginfo ("Received $control_name == $curr_state_bin");
#
#        # TODO can't just assume the last_value == true means the window is open.
#        # some sensors could be the other way around.
#        if ( exists $window_sensor_to_control_name_map->{$control_name}
#            &&  $curr_state_bin == true ) {
#            my $operate_control_name
#                 = $window_sensor_to_control_name_map->{$control_name};
#
#            send_cmd( $operate_control_name, OFF() );
#        }
#    }

}

#{
#    my $thermometer_conf;
#
#    eval { $thermometer_conf = get_one_wire_heating_control_conf();};
#    if ($@) {
#        klogerror "Reading in the conf.";
#        klogerror $@;
#        klogfatal "Please check the conf file $HEATING_DAEMON_CONF_FULLPATH";
#    }
#
#    sub process_thermometer_msg {
#        my ($zmq_sock, $msg, $param) = @_;
#
#        my $msg_rh = $json->decode( $msg );
#
#        my $control_name       = get_hashval($msg_rh, 'control_name');
#        my $current_state = get_hashval($msg_rh, 'current_state');
#        my $request_epoch_time = get_hashval($msg_rh, 'request_epoch_time');
#        my $owaddr             = get_hashval($msg_rh, 'onewire_addr');
#
#        my $new_thermometer_conf ;
#        eval { $new_thermometer_conf = get_one_wire_heating_control_conf();};
#        if ($@ ) {
#            klogerror "Getting the conf.";
#            klogerror "Probably a broken conf $HEATING_DAEMON_CONF_FULLPATH";
#            klogerror "$@";
#            klogerror "Using the old conf";
#        }
#        $thermometer_conf = $new_thermometer_conf || $thermometer_conf ;
#
#        my $tc   = $thermometer_conf->{$owaddr};
#
#        klogwarn "One-wire address $owaddr isn't in "
#            ."$HEATING_DAEMON_CONF_FULLPATH config file"
#                if ! defined $tc ;
#
#        my $name = $tc->{name} || '';
#        klogerror "'name' isn't defined for one-wire address $owaddr in "
#           ."$HEATING_DAEMON_CONF_FULLPATH "
#                if ! $name ;
#
#        my $operate_control_name = $tc->{control} || '';
#        my $upper_temp   = $tc->{upper_temp} || '';
#
#        if ( ! $operate_control_name && ! $upper_temp ){
#            klogdebug "$name : $owaddr : $current_state C";
#            return ;
#        }
#
#        my $lower_temp = $tc->{lower_temp} || ( $upper_temp - 1 );
#
#        if ( ! $operate_control_name || ! defined $upper_temp || ! defined $lower_temp ){
#            klogerror "Not all the parameters are configured for this thermometer";
#            klogerror "Both the 'upper_temp' and 'control' need to be defined";
#            klogerror "upper_temp = $upper_temp C";
#            klogerror "control    = '$operate_control_name'";
#            klogerror "Please fix the config file $HEATING_DAEMON_CONF_FULLPATH";
#            return;
#        }
#
#        if ( $upper_temp <= $lower_temp ){
#            klogerror "Broken temperature range in $HEATING_DAEMON_CONF_FULLPATH config.";
#            klogerror "(Upper) $upper_temp C <= $lower_temp C (Lower)";
#            klogerror "Upper temperature must be greater than the lower temperature";
#            klogerror "Please fix the config file $HEATING_DAEMON_CONF_FULLPATH";
#            klogerror "Cannot operate this control.";
#            return;
#        }
#
#        kloginfo "$name : $owaddr : $current_state C : lower = $lower_temp C : upper = $upper_temp C";
#        klogdebug "msg", $msg_rh;
#
##        my $send_cmd = sub {
##            my ( $action ) = @_;
##            my $retval;
##            kloginfo "Send command to '$operate_control_name' '$action'";
##            eval { $retval = queue_command($operate_control_name, $action); };
##            if ( $@ ) {
##                klogerror "$@";
##                return
##            }
##        };
#
##        my $window_sensor ==
#        if ( exists $tc->{window_sensor}) {
#            kloginfo "$operate_control_name . $tc->{window_sensor} is $last_control_state->{$tc->{window_sensor}}{last_value}";
#
#            $window_sensor_to_control_name_map->{$tc->{window_sensor}} = $operate_control_name;
#        }
#
#
#        if ( $current_state > $upper_temp ){
#            send_cmd($operate_control_name, OFF);
#        }
#        elsif ( $current_state < $lower_temp ){
#
#            # TODO : This code is copied below. It's horrible. Needs re-writing.
#            # switch off if the window is open :
#            if ( exists $tc->{window_sensor}  ){
#
#                # TODO can't just assume the last_value == true means the window is open.
#                # some sensors could be the other way around.
#                if ( $last_control_state->{$tc->{window_sensor}}{last_value} == true ){
#                    klogwarn "$operate_control_name is being switched off because $tc->{window_sensor} is open";
#                    send_cmd($operate_control_name, OFF);
#                } else {
#                    kloginfo "$operate_control_name is being switched on. $tc->{window_sensor} is closed";
#
#                    send_cmd($operate_control_name, ON);
#                }
#
#            } else {
#
#                kloginfo "$operate_control_name doesn't have a window sensor";
#
#                send_cmd($operate_control_name, ON);
#            }
#        } else {
#
#            if ( exists $tc->{window_sensor}) {
#
#                # TODO can't just assume the last_value == true means the window is open.
#                # some sensors could be the other way around.
#                if ( $last_control_state->{$tc->{window_sensor}}{last_value} == true ){
#                    klogwarn "$operate_control_name is being switched off because $tc->{window_sensor} is open";
#                    send_cmd($operate_control_name, OFF);
#                } else {
#                    kloginfo "$operate_control_name is being left on. $tc->{window_sensor} is closed";
#                }
#            }
#
#            kloginfo "$operate_control_name : Current temperate is in correct range\n";
#        }
#    }
#}

1;
