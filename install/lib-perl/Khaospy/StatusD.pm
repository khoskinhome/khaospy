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

use Khaospy::DBH qw(
    dbh
    get_last_control_state
    init_last_control_state
);

use zhelpers;

use Khaospy::Constants qw(
    $JSON
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS

    $LOCALHOST

    $RRD_DIR

    $ONEWIRE_THERM_CONTROL_TYPE
    $PI_STATUS_RRD_UPDATE_TIMEOUT

    $TIMER_AFTER_COMMON
    $PI_STATUS_DAEMON_TIMER

    $ONE_WIRE_DAEMON_PERL_PORT
    $ONE_WIRE_SENDER_PERL_SCRIPT

    $PI_CONTROLLER_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SCRIPT

    $OTHER_CONTROLS_DAEMON_SEND_PORT
    $OTHER_CONTROLS_DAEMON_SCRIPT

    $MAC_SWITCH_DAEMON_SEND_PORT
    $MAC_SWITCH_DAEMON_SCRIPT

    $SCRIPT_TO_PORT

);

use Khaospy::Conf::Controls qw(
    get_rrd_create_params_for_control
    is_control_rrd_graphed
    get_control_config
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogextra klogdebug
);

use Khaospy::DBH::Controls qw(
    control_status_insert
);

use Khaospy::Conf::PiHosts qw(
    get_pi_hosts_running_daemon
);

use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;

use Khaospy::Utils qw(
    get_hashval
    timestamp
    burp
    get_iso8601_utc_from_epoch
    trans_ON_to_value_or_return_val
);

our @EXPORT_OK = qw( run_status_d );

our $LOGLEVEL;

my $last_db_control_status_purge;
my $last_control_state;

my $days_to_keep;
my $purge_secs;

sub run_status_d {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;

    klogstart "StatusD Subscribe all Controls, all hosts START";

    $Khaospy::Log::OVERRIDE_CONF_LOGLEVEL = $opts->{"log_level"}
        if $opts->{"log_level"};

    kloginfo "CLI : log_level = ".$Khaospy::Log::OVERRIDE_CONF_LOGLEVEL
        if defined $Khaospy::Log::OVERRIDE_CONF_LOGLEVEL;

    $days_to_keep = $opts->{"days_to_keep"} if $opts->{"days_to_keep"};
    kloginfo  "CLI : days_to_keep = $days_to_keep" if defined $days_to_keep;
    klogfatal "CLI : days_to_keep is not a positive integer"
        if defined $days_to_keep && $days_to_keep !~ /^\d+$/;

    $purge_secs = $opts->{"purge_secs"} if defined $opts->{"purge_secs"};
    kloginfo  "CLI : purge_secs = $purge_secs" if defined $purge_secs;
    klogfatal "CLI : purge_secs is not a positive integer"
        if defined $purge_secs && $purge_secs !~ /^\d+$/;

    $last_control_state = get_last_control_state();

    $last_db_control_status_purge = time;

    my @w;

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
                msg_handler       => \&output_msg,
                msg_handler_param => $port,
                klog              => true,
            });
        }

    }

    push @w, AnyEvent->timer(
        after    => $TIMER_AFTER_COMMON,
        interval => $PI_STATUS_DAEMON_TIMER,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {

    for my $control_name ( keys %$last_control_state ) {
        # One wire thermometers will get a regular update,
        # so these can be ignored :
        my $control_conf = get_control_config($control_name);
        next if get_hashval($control_conf, 'type')
            eq $ONEWIRE_THERM_CONTROL_TYPE;

        if ( is_control_rrd_graphed($control_name) ){

            if ( $last_control_state->{$control_name}{last_rrd_update_time}
                + $PI_STATUS_RRD_UPDATE_TIMEOUT
                    < time
            ){
                klogextra "Update RRD for $control_name with last_value (timeout)";
                update_rrd( $control_name, time,
                    get_hashval(
                        get_hashval($last_control_state, $control_name),
                        'last_value',
                        true
                    )
                );
            }

        }
    }

    purge_control_status()
        if ( $purge_secs
             && time > $last_db_control_status_purge + $purge_secs
        );
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

    my $request_epoch_time = $dec->{request_epoch_time};

    my $record = {
        control_name  => $control_name,
        current_state => $dec->{current_state} || "",
        current_value => $dec->{current_value},
        last_change_state_time =>
            get_iso8601_utc_from_epoch($dec->{last_change_state_time}) || undef,
        last_change_state_by => $dec->{last_change_state_by} || undef,
        manual_auto_timeout_left => $dec->{manual_auto_timeout_left} ,
        request_time =>
            get_iso8601_utc_from_epoch($request_epoch_time),
    };

    my $curr_state_or_value =
        trans_ON_to_value_or_return_val(
            $dec->{current_state} || $dec->{current_value}
        );

    if ( ! defined $curr_state_or_value ){
        if ( exists $last_control_state->{$control_name} ){
            $curr_state_or_value
                = $last_control_state->{$control_name}{last_value};

            klogwarn "$control_name is undefined. Using last value for update ($curr_state_or_value)";
        }
    }

    if ( exists $last_control_state->{$control_name}
        && $last_control_state->{$control_name}{last_value} == $curr_state_or_value
        && $last_control_state->{$control_name}{statusd_updated}
    ){
        klogdebug "Do NOT update DB with $control_name : $curr_state_or_value";
    } else {

        init_last_control_state($last_control_state, $control_name);

        $last_control_state->{$control_name}{last_value} = $curr_state_or_value;
        klogextra "Update DB with $control_name : $curr_state_or_value";

        # TODO capture any exceptions from the following and log an error :
        control_status_insert( $record );
        $last_control_state->{$control_name}{statusd_updated} = true;
    }

    update_rrd( $control_name, $request_epoch_time, $curr_state_or_value);

}

sub update_rrd {

    my ($control_name,$request_epoch_time,$curr_state_or_value) = @_;

    return if ! is_control_rrd_graphed($control_name);

    init_last_control_state($last_control_state, $control_name);

    # Does an rrd exist ? If not then create it.
    my $rrd_filename = "$RRD_DIR/$control_name";
    if ( ! -f $rrd_filename ){

        kloginfo "Creating RRD file $rrd_filename";
        my $cmd =
        "rrdtool create $rrd_filename "
            .join ( ' ', @{get_rrd_create_params_for_control($control_name)});

        klogdebug "cmd = $cmd";
        system ($cmd); # TODO error checking
    }

    klogextra "Updating RRD file $rrd_filename $request_epoch_time:$curr_state_or_value";
    my $cmd = "rrdtool update $rrd_filename $request_epoch_time:$curr_state_or_value";
    system($cmd); #TODO ERROR CHECKING.

    $last_control_state->{$control_name}{last_rrd_update_time}
        = $request_epoch_time;
    $last_control_state->{$control_name}{last_value}
        = $curr_state_or_value;

}

sub purge_control_status {

    return if not $days_to_keep;

    kloginfo "Purging the DB control_status data older than $days_to_keep days";

    # days_to_keep is validated as only containing integer digits.
    # So there shouldn't be any SQL injection vector via the CLI in this code.
    klogfatal "purge_control_status() : days_to_keep is not a positive integer"
        if $days_to_keep !~ /^\d+$/;

    my $sql = <<"    EOSQL";
        delete from control_status
        where request_time < NOW() - interval '$days_to_keep days';
    EOSQL

    my $sth = dbh->prepare( $sql );

    eval { $sth->execute(); };

    klogerror "$@ \n" if $@;
}

1;
