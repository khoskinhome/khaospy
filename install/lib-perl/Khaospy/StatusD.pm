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

use Khaospy::DBH qw(dbh);

use zhelpers;

use Khaospy::Constants qw(
    $JSON
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS

    $LOCALHOST

    $ONE_WIRE_DAEMON_PERL_PORT
    $ONE_WIRE_SENDER_PERL_SCRIPT

    $PI_CONTROLLER_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SCRIPT

    $OTHER_CONTROLS_DAEMON_SEND_PORT
    $OTHER_CONTROLS_DAEMON_SCRIPT

    $MAC_SWITCH_DAEMON_SEND_PORT
    $MAC_SWITCH_DAEMON_SCRIPT

    $PING_SWITCH_DAEMON_SEND_PORT
    $PING_SWITCH_DAEMON_SCRIPT
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

use Khaospy::Utils qw(
    timestamp
    burp
    get_iso8601_utc_from_epoch
);

our @EXPORT_OK = qw( run_status_d );

our $LOGLEVEL;

our $OPTS;

my $script_to_port = {
    $ONE_WIRE_SENDER_PERL_SCRIPT
        => $ONE_WIRE_DAEMON_PERL_PORT,

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

    klogstart "StatusD Subscribe all Controls, all hosts START";
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

    my $dec;
    eval { $dec = $JSON->decode($msg); };
    if ($@) {
        klogerror "msg $port";
        return;
    }

    # current_state is either "on" or "off"
    # current_value is for thermometer type values

    my $control_name = $dec->{control_name};

    my $record = {
        control_name  => $control_name,
        current_state => $dec->{current_state} || "",
        current_value => $dec->{current_value},
        last_change_state_time =>
            get_iso8601_utc_from_epoch($dec->{last_change_state_time}) || undef,
        last_change_state_by => $dec->{last_change_state_by} || undef,
        manual_auto_timeout_left => $dec->{manual_auto_timeout_left} ,
        request_time =>
            get_iso8601_utc_from_epoch($dec->{request_epoch_time}),
    };

    my $curr_state_or_value
        = trans_ON_to_value($dec->{current_state} || $dec->{current_value});

    $curr_state_or_value = 'undefined' if ! defined $curr_state_or_value;

    if ( exists $last_control_state->{$control_name}
        && $last_control_state->{$control_name} == $curr_state_or_value
    ){
        klogdebug "Do NOT update DB with $control_name : $curr_state_or_value";
    } else {
        $last_control_state->{$control_name} = $curr_state_or_value;
        kloginfo "Update DB with $control_name : $curr_state_or_value";
        control_status_insert( $record );
    }
}

sub trans_ON_to_value { # and OFF to false
    my ($ONOFF) = @_;

    return $ONOFF if $ONOFF !~ /^[a-z]+$/i;

    return true  if $ONOFF eq ON;
    return false if $ONOFF eq OFF;

    klogfatal "Can't translate a non ON or OFF value ($ONOFF) to value";

}

sub control_status_insert {
    my ( $values ) = @_;
    my $sql = <<"    EOSQL";
    INSERT INTO control_status
    ( control_name, current_state, current_value,
      last_change_state_time, last_change_state_by,
      manual_auto_timeout_left,
      request_time, db_update_time
    )
    VALUES
    ( ?,?,?,?,?,?,?,NOW() );
    EOSQL

    my $sth = dbh->prepare( $sql );

    $sth->execute(
        $values->{control_name},
        $values->{current_state},
        $values->{current_value},
        $values->{last_change_state_time},
        $values->{last_change_state_by},
        $values->{manual_auto_timeout_left},
        $values->{request_time},
    );
}

# TODO the rrdupdater for those controls that are configured.

1;
