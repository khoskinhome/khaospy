package Khaospy::Log;
use strict; use warnings;

use Exporter qw/import/;
our @EXPORT_OK = qw(
    klog START FATAL ERROR WARN INFO EXTRA DEBUG
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogextra klogdebug
);

use Carp qw/confess/;
use Sys::Hostname;
use Data::Dumper;

use Khaospy::Conf::PiHosts qw/get_this_pi_host_config/;
use Khaospy::Utils qw/timestamp/;

use Khaospy::Conf::Global qw(
    gc_ERROR_LOG_DAEMON_SEND_PORT
);

use Khaospy::Constants qw(
    $JSON
    $ZMQ_CONTEXT
    $ERROR_LOG_DAEMON_SCRIPT
);

use Khaospy::Conf::PiHosts qw(
    get_pi_hosts_running_daemon
);

use ZMQ::LibZMQ3;
use ZMQ::Constants qw( ZMQ_PUB );
use zhelpers;

sub START {"start"};
sub FATAL {"fatal"};
sub ERROR {"error"};
sub WARN  {"warn"};
sub INFO  {"info"};
sub EXTRA {"extra"};
sub DEBUG {"debug"};

sub klogstart ($;$$$$) { klog(START,@_) };
sub klogfatal ($;$$$$) { klog(FATAL,@_) };
sub klogerror ($;$$$$) { klog(ERROR,@_) };
sub klogwarn  ($;$$$$) { klog(WARN ,@_) };
sub kloginfo  ($;$$$$) { klog(INFO ,@_) };
sub klogextra ($;$$$$) { klog(EXTRA,@_) };
sub klogdebug ($;$$$$) { klog(DEBUG,@_) };

=pod
    types
        ERROR
        WARN
        INFO
        DEBUG

    format of a log line :
        timestamp|type|host|pid|message

=cut

my $type_to_val = {
    start =>1,
    fatal =>2,
    error =>3,
    warn  =>4,
    info  =>5,
    extra =>6,
    debug =>7,
};

our $OVERRIDE_CONF_LOGLEVEL;

my $zmq_publisher = [] ;

sub _get_zmq_pub {

    return if @$zmq_publisher;

    for my $pub_host (@{get_pi_hosts_running_daemon($ERROR_LOG_DAEMON_SCRIPT)}){

        my $zmq_p = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);

        my $pub_to_port = "tcp://$pub_host:".gc_ERROR_LOG_DAEMON_SEND_PORT;

        if ( my $zmq_state = zmq_connect($zmq_p, $pub_to_port )){
            # zmq_connect returns zero on success.
            warn "context is $ZMQ_CONTEXT\n";
            confess "zmq can't connect to $pub_to_port. status = $zmq_state. $!\n";
        };

        push @$zmq_publisher, $zmq_p;

    }
}

sub klog {
    my ( $type, $msg, $dump, $exception, $no_publish, $control_name ) = @_;
    $type = lc ($type);

    _get_zmq_pub();

    my $pi_host_log_level ;
    eval { $pi_host_log_level = get_this_pi_host_config()->{log_level}; };
    $pi_host_log_level = "debug" if $@;

    my $log_level = $OVERRIDE_CONF_LOGLEVEL || $pi_host_log_level;

    my $log_level_val = $type_to_val->{$log_level};

    $log_level_val = 6 if ! $log_level_val;

    confess "Illegal log type of $type\n"
        if ! exists $type_to_val->{$type};

    my $line = timestamp."|".uc($type)."|".hostname."|$$|$msg|";
    $line .= "Dump :\n".Dumper($dump) if $dump;
    $line .= "\n";

    if ( ( $type eq "fatal" || $type eq "error" )
        && ! $no_publish
    ){
        my $send_msg = {
            e_host         => hostname,
            e_script       => $0,
            e_time         => time,
            e_timestamp    => timestamp,
            e_message      => $msg,
            e_control_name => $control_name,
        };

        # TODO add the $dump ?

        my $json_msg = $JSON->encode($send_msg);

        for my $elog_pub ( @$zmq_publisher ) {
            zhelpers::s_send( $elog_pub, "$json_msg" );
        }

    }

    $exception->throw($line) if $exception;
    confess $line if $type eq "fatal" ;

    my $tval = $type_to_val->{$type};

    # only warn, info and debug can be switched off from logging
    print STDERR $line if $tval <= $log_level_val or $tval <= 3;
}

1;
