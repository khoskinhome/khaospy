package Khaospy::Conf::Global;
use strict; use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2017

# Things will migrate from Constants to here,
# so that they are settable in the global-conf.
# This is generally things like timers, counters, timeouts, ports, time-zone etc

use Exporter qw/import/;
our @EXPORT_OK = qw(
    get_global_conf

    gc_TEMP_RANGE_DEG_C

    gc_PI_STATUS_DAEMON_TIMER
    gc_PI_STATUS_DAEMON_WEBUI_VAR_TIMER
    gc_PI_STATUS_DAEMON_WEBUI_VAR_PUB_COUNT
    gc_PI_STATUS_RRD_UPDATE_TIMEOUT

    gc_ONE_WIRE_DAEMON_PERL_PORT
    gc_QUEUE_COMMAND_PORT
    gc_COMMAND_QUEUE_DAEMON_SEND_PORT
    gc_PI_CONTROLLER_DAEMON_SEND_PORT
    gc_PI_STATUS_DAEMON_SEND_PORT
    gc_OTHER_CONTROLS_DAEMON_SEND_PORT
    gc_MAC_SWITCH_DAEMON_SEND_PORT
    gc_ERROR_LOG_DAEMON_SEND_PORT
    gc_SCRIPT_TO_PORT

);

use Khaospy::Constants qw(
    $GLOBAL_CONF_FULLPATH

    $ONE_WIRE_SENDER_PERL_SCRIPT
    $PI_CONTROLLER_DAEMON_SCRIPT
    $OTHER_CONTROLS_DAEMON_SCRIPT
    $MAC_SWITCH_DAEMON_SCRIPT
    $PI_STATUS_DAEMON_SCRIPT

);

use Khaospy::Conf;

my $global_conf;

sub get_global_conf {
    my ($force_reload) = @_;
    Khaospy::Conf::get_conf( \$global_conf, $GLOBAL_CONF_FULLPATH, $force_reload);
}

#######################

sub gc_TEMP_RANGE_DEG_C {

    get_global_conf() if ! $global_conf;
    # This is the default range between the upper and lower temperatures
    # This is used in the webui for displaying too-cold, just-right and too-hot
    # It is also used by the rules for switching on and off heating devices.
    # Also one-wire-therm-controls can have this set on an individual basis,
    # via another WEBUI_VAR_FLOAT_CONTROL_TYPE control.
    # ( the control setting will take precedence over this )
    $global_conf->{temp_range_deg_c} || 1;
}

sub gc_PI_STATUS_DAEMON_TIMER {
    get_global_conf() if ! $global_conf;
    # How often the rrds are checked if they haven't been updated.
    $global_conf->{pi_status_daemon_timer} || 120;
}

sub gc_PI_STATUS_DAEMON_WEBUI_VAR_TIMER {
    get_global_conf() if ! $global_conf;
    # how often the WEBUI_VAR controls are checked for changes.
    $global_conf->{pi_status_daemon_webui_var_timer} || 5;
}

sub gc_PI_STATUS_DAEMON_WEBUI_VAR_PUB_COUNT {
    get_global_conf() if ! $global_conf;
    # The amount of publishes when a WEBUI_VAR control changes.
    $global_conf->{pi_status_daemon_webui_var_pub_count} || 3;
}

sub gc_PI_STATUS_RRD_UPDATE_TIMEOUT {
    get_global_conf() if ! $global_conf;
    # Infrequently updated controls need there RRDs updated with old values.
    # otherwise you see holes in the graph.
    $global_conf->{pi_status_rrd_update_timeout} || 120;
}

################

sub gc_ONE_WIRE_DAEMON_PERL_PORT {
    get_global_conf() if ! $global_conf;
    $global_conf->{one_wire_daemon_perl_port} || 5002;
}

sub gc_QUEUE_COMMAND_PORT {
    get_global_conf() if ! $global_conf;
    $global_conf->{queue_command_port} || 5063;
}
# Do gc_QUEUE_COMMAND_PORT and gc_COMMAND_QUEUE_DAEMON_SEND_PORT
# need renaming ?
sub gc_COMMAND_QUEUE_DAEMON_SEND_PORT {
    get_global_conf() if ! $global_conf;
    $global_conf->{command_queue_daemon_send_port} || 5061;
}

sub gc_PI_CONTROLLER_DAEMON_SEND_PORT {
    get_global_conf() if ! $global_conf;
    $global_conf->{pi_controller_daemon_send_port} || 5062;
}

sub gc_PI_STATUS_DAEMON_SEND_PORT {
    get_global_conf() if ! $global_conf;
    $global_conf->{pi_status_daemon_send_port} || 5064 ;
}

sub gc_OTHER_CONTROLS_DAEMON_SEND_PORT {
    get_global_conf() if ! $global_conf;
    $global_conf->{other_controls_daemon_send_port} || 5065;
}

sub gc_MAC_SWITCH_DAEMON_SEND_PORT {
    get_global_conf() if ! $global_conf;
    $global_conf->{mac_switch_daemon_send_port} || 5005;
}

sub gc_ERROR_LOG_DAEMON_SEND_PORT {
    get_global_conf() if ! $global_conf;
    $global_conf->{error_log_daemon_send_port} || 5066;
}

sub gc_SCRIPT_TO_PORT {
    get_global_conf() if ! $global_conf;
    return {
        $ONE_WIRE_SENDER_PERL_SCRIPT
            => gc_ONE_WIRE_DAEMON_PERL_PORT,

        $PI_CONTROLLER_DAEMON_SCRIPT
            => gc_PI_CONTROLLER_DAEMON_SEND_PORT,

        $OTHER_CONTROLS_DAEMON_SCRIPT
            => gc_OTHER_CONTROLS_DAEMON_SEND_PORT,

        $MAC_SWITCH_DAEMON_SCRIPT
            => gc_MAC_SWITCH_DAEMON_SEND_PORT,

        $PI_STATUS_DAEMON_SCRIPT
            => gc_PI_STATUS_DAEMON_SEND_PORT,
    };
}

#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}
#
#sub gc_ {
#
#    $global_conf->{} || ;
#
#}

1;
