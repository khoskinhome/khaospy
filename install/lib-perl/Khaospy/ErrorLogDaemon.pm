package Khaospy::ErrorLogDaemon;
use strict;
use warnings;

=pod

=cut

use Try::Tiny;
use Time::HiRes qw/usleep time/;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak confess/;
use Sys::Hostname;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_SUBSCRIBE
    ZMQ_FD
    ZMQ_SUB
);

use Khaospy::Conf::Controls qw(
    get_control_config
);

use Khaospy::Conf::PiHosts qw/
    get_pi_hosts_running_daemon
/;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON
    true false
    STATUS

    $ERROR_LOG_DAEMON
    $ERROR_LOG_DAEMON_SCRIPT
    $ERROR_LOG_DAEMON_SEND_PORT
    $ERROR_LOG_DAEMON_TIMER

    $TIMER_AFTER_COMMON
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

use Khaospy::Utils qw(
    get_hashval
);

use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;
use zhelpers;

our @EXPORT_OK = qw(
    run_error_log_daemon
);

sub run_error_log_daemon {

    klogstart "$ERROR_LOG_DAEMON START";

    my @w;

    push @w, zmq_anyevent({
        zmq_type    => ZMQ_SUB,
        bind        => true,
        host        => "*",
        port        => $ERROR_LOG_DAEMON_SEND_PORT,
        msg_handler => \&error_message,
        klog        => true,
    });

    push @w, AnyEvent->timer(
        after    => $TIMER_AFTER_COMMON,
        interval => $ERROR_LOG_DAEMON_TIMER,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {
    klogdebug "in timer ";

}

sub error_message {
    my ($zmq_sock, $msg, $param ) = @_;

    my $msg_p;

    eval{$msg_p = $JSON->decode( $msg );};
    if ($@) {
        confess "JSON decode of message failed. $@";
    }

    print "#################\n";
    print Dumper($msg_p)."\n";

    # TODO actually store this in an error_log db table.
    # OR MAYBE JUST broadcast messages for certain controls when requested.
    # keeping the last say hours worth in memory.

}

1;
