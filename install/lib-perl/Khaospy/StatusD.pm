package Khaospy::StatusD;
use strict;
use warnings;
use Time::HiRes qw/time/;

# subscribes to all controls publishers, and records status in DB.

use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use Sys::Hostname;
use POSIX qw/strftime/;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_SUB
);

use zhelpers;

use Khaospy::Constants qw(
    $JSON
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS

    $LOCALHOST

    $ONE_WIRE_DAEMON_PORT
    $ONE_WIRED_SENDER_SCRIPT

    $PI_CONTROLLER_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SCRIPT

    $OTHER_CONTROLS_DAEMON_SEND_PORT
    $OTHER_CONTROLS_DAEMON_SCRIPT

    $MAC_SWITCH_DAEMON_SEND_PORT
    $MAC_SWITCH_DAEMON_SCRIPT

    $PING_SWITCH_DAEMON_SEND_PORT
    $PING_SWITCH_DAEMON_SCRIPT
);

use Khaospy::Conf qw(
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
    DEBUG
);

use Khaospy::Conf::PiHosts qw(
    get_pi_hosts_running_daemon
);

use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;

use Khaospy::Utils qw( timestamp burp );

our @EXPORT_OK = qw( run_status_d );

our $LOGLEVEL;

our $OPTS;

my $script_to_port = {
    $ONE_WIRED_SENDER_SCRIPT
        => $ONE_WIRE_DAEMON_PORT,

    $PI_CONTROLLER_DAEMON_SCRIPT
        => $PI_CONTROLLER_DAEMON_SEND_PORT,

    $OTHER_CONTROLS_DAEMON_SCRIPT
        => $OTHER_CONTROLS_DAEMON_SEND_PORT,

    $MAC_SWITCH_DAEMON_SCRIPT
        => $MAC_SWITCH_DAEMON_SEND_PORT,

    $PING_SWITCH_DAEMON_SCRIPT
        => $PING_SWITCH_DAEMON_SEND_PORT,
};

my $last_control_state = {};

sub run_status_d {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;
    $OPTS = $opts;
    $Khaospy::Log::OVERRIDE_CONF_LOGLEVEL = $opts->{"log-level"} || DEBUG;

    kloginfo "StatusD Subscribe all Controls, all hosts START";
    kloginfo "LOGLEVEL = ".$Khaospy::Log::OVERRIDE_CONF_LOGLEVEL;

    my @w;

    for my $script ( keys %$script_to_port ){
        my $port = $script_to_port->{$script};
        for my $sub_host (
            @{get_pi_hosts_running_daemon($script)}
        ){
            kloginfo "Subscribing to $sub_host : $script : $port";
            push @w, zmq_anyevent({
                zmq_type          => ZMQ_SUB,
                host              => $sub_host,
                port              => $port,
                msg_handler       => \&output_msg,
                msg_handler_param => $port,
                klog              => true,
            });
        }

    }
    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub output_msg {
    my ( $zmq_sock, $msg, $port ) = @_;

    #kloginfo "msg $msg ";

    return if $msg =~ /^oneWireThermometer/;

#    # hack , when I stop the one-wire-thermometer doing this
#    # the following line and sub will be removed.
#    $msg = map_one_wire_thermometer($msg)
#        if =~ /^oneWireThermometer/;

    my $dec;
    eval { $dec = $JSON->decode($msg); };
    if ($@) {
        klogerror "msg $port";
        return;
    }

    my $control_name = $dec->{control_name};
    my $current_state = trans_ON_to_value($dec->{current_state});

#    $dec->{last_change_state_time},
#    $dec->{last_change_state_by},
#    $dec->{manual_auto_timeout_left},
#    $dec->{request_epoch_time},

    if ( exists $last_control_state->{$control_name}
        && $last_control_state->{$control_name} == $current_state
    ){
       print "## Do NOT update DB with this :\n";
    } else {
        $last_control_state->{$control_name} = $current_state;
    }

    print "control name $control_name\n";
    print "current state $current_state\n";
    print "last chng time ".$dec->{last_change_state_time}."\n";
    print "last chng by ".$dec->{last_change_state_by}."\n";
    print "man auto timeout ".$dec->{manual_auto_timeout_left}."\n";
    print "request time ".$dec->{request_epoch_time}."\n";
    print "\n";
}

sub map_one_wire_thermometer {
    my ($msg ) = @_;
#        if =~ /^oneWireThermometer/;

}

sub trans_ON_to_value { # and OFF to false
    my ($ONOFF) = @_;

    return $ONOFF if $ONOFF !~ /^[a-z]+$/i;

    return true  if $ONOFF eq ON;
    return false if $ONOFF eq OFF;

    klogfatal "Can't translate a non ON or OFF value ($ONOFF) to value";

}

#  action                              => status
#  control_host                        => piserver
#    $dec->{control_name}                        => amelia_pir
#  current_state                       => on
#  last_change_state                   => on
#  last_change_state_time              => 2016-04-30 23:01:17.5933 GMT
#  message_from                        => khaospy-pi-controls-d.pl
#  message_type                        => poll-update
#  poll_epoch_time                     => 2016-04-30 23:01:17.5936 GMT
#  request_epoch_time                  => 2016-04-30 23:01:17.5936 GMT
#
#####
#
#  action                              => off
#  action_epoch_time                   => 2016-04-30 23:06:31.0280 GMT
#  control_host                        => piboiler
#  control_name                        => boiler
#  control_type                        => pi-gpio-relay-manual
#  current_state                       => off
#  last_auto_gpio_relay_change         => 0
#  last_auto_gpio_relay_change_time    => 2016-04-30 21:39:02.8306 GMT
#  last_broadcast_time                 => 2016-04-30 23:06:30.9846 GMT
#  last_change_state_by                => auto
#  last_change_state_time              => 2016-04-30 21:39:02.8306 GMT
#  last_manual_gpio_detect_change      => 1
#  last_manual_gpio_detect_change_time => 2016-04-30 21:26:00.6302 GMT
#  manual_auto_timeout_left            => 0
#  message_from                        => khaospy-pi-controls-d.pl
#  message_type                        => operation-status
#  request_epoch_time                  => 2016-04-30 23:06:30.9793 GMT
#  request_host                        => piboiler
#
#####
#
#  action                              => off
#  action_epoch_time                   => 2016-04-30 23:06:30.9660 GMT
#  control_host                        => alisonrad.khaos
#  control_name                        => alisonrad
#  control_type                        => orviboS20
#  current_state                       => off
#  last_broadcast_time                 => 2016-04-30 23:06:30.5625 GMT
#  last_change_state                   => off
#  last_change_state_by                => auto
#  last_change_state_time              => 2016-04-30 06:26:48.4183 GMT
#  last_manual_change_time             => 2016-04-29 14:19:11.9555 GMT
#  last_poll_time                      => 2016-04-30 23:06:22.8769 GMT
#  manual_auto_timeout_left            => 0
#  message_from                        => khaospy-other-controls-d.pl
#  message_type                        => operation-status
#  request_epoch_time                  => 2016-04-30 23:06:30.5573 GMT
#  request_host                        => piboiler
#

1;
