package Khaospy::ZMQSubscribeAllPublishers;
use strict; use warnings;
# used by CLI khaospy-zmq-subscribe.pl to listen to all publishers on a host.

use Exporter qw/import/;
our @EXPORT_OK = qw( run_subscribe_all );

use Time::HiRes qw/time/;
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

use Khaospy::Conf::Global qw(
    gc_ONE_WIRE_DAEMON_PERL_PORT
    gc_COMMAND_QUEUE_DAEMON_SEND_PORT
    gc_PI_CONTROLLER_DAEMON_SEND_PORT
    gc_OTHER_CONTROLS_DAEMON_SEND_PORT
    gc_PI_STATUS_DAEMON_SEND_PORT
    gc_MAC_SWITCH_DAEMON_SEND_PORT
);

use Khaospy::Constants qw(
    $JSON
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS

    $LOCALHOST

    $RRD_IMAGE_DIR
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
    DEBUG
);

use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;

use Khaospy::Utils qw( timestamp burp );

our $LOGLEVEL;

our $OPTS;

sub run_subscribe_all {
    my ( $opts ) = @_;
    $opts = {} if ! $opts;
    $OPTS = $opts;
    $Khaospy::Log::OVERRIDE_CONF_LOGLEVEL = $opts->{"log-level"} || DEBUG;

    my $sub_host = $opts->{"host"} || $LOCALHOST;

    kloginfo "Subscribe all Publishers START";
    kloginfo "LOGLEVEL = ".$Khaospy::Log::OVERRIDE_CONF_LOGLEVEL;
    kloginfo "HOST     = ".$sub_host;

    my @subscribe_ports = get_ports($opts);

    kloginfo "Subscribing to ", \@subscribe_ports;

    my @w;

    # TODO needs to be able to subscribe to multiple hosts.

    for my $port ( @subscribe_ports ){
        push @w, zmq_anyevent({
            zmq_type          => ZMQ_SUB,
            host              => $sub_host,
            port              => $port,
            msg_handler       => \&output_msg,
            msg_handler_param => $port,
            klog              => true,
        });
    }

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub output_msg {
    my ( $zmq_sock, $msg, $port ) = @_;

    my $dec;
    eval { $dec = $JSON->decode($msg); };
    if ($@) {
        kloginfo "msg on port $port";
        output ("$msg\n" );
        return;
    }

    if ( exists $dec->{control_name} and $OPTS->{'filter-control'} ){
        return if $dec->{control_name} !~ m/$OPTS->{'filter-control'}/;
    }
    kloginfo "msg on port $port";

    my $convert_times = sub {
        my ( $key, $value ) = @_;

        my $r_val = $value;

        if ($key =~ /_time$/){
            my $fraction = $value - int($value);

            my ($frac_str) = $fraction
                =~ /^0\.(\d{4})/;

            $frac_str = 0 if ! defined $frac_str;

            $r_val = sprintf("%s.%s GMT",
                strftime("%F %T", gmtime($value)),
                $frac_str
            );
        }

        my $spaces = 36 - length($key);
        my $pad = " " x ($spaces > 0 ? $spaces : 1 );

        return sprintf("  %s%s=> %s", $key, $pad, $r_val);
    };

    my @out = map { $convert_times->($_, $dec->{$_}) } keys %$dec;
    output ( join( "\n" , sort @out )."\n" );

}

sub output {
    my ($out) = @_;
    print $out;
}

sub get_ports {
    my ($opts) = @_;
    my @ports;

    push @ports, gc_ONE_WIRE_DAEMON_PERL_PORT
        if $opts->{"one-wire"};

    push @ports, gc_COMMAND_QUEUE_DAEMON_SEND_PORT
        if $opts->{"command-queue"};

    push @ports, gc_PI_CONTROLLER_DAEMON_SEND_PORT
        if $opts->{"pi-control"};

    push @ports, gc_OTHER_CONTROLS_DAEMON_SEND_PORT
        if $opts->{"other-control"};

    push @ports, gc_PI_STATUS_DAEMON_SEND_PORT
        if $opts->{"status"};

    push @ports, gc_MAC_SWITCH_DAEMON_SEND_PORT
        if $opts->{"mac"};

    @ports = (
        gc_ONE_WIRE_DAEMON_PERL_PORT,
        gc_COMMAND_QUEUE_DAEMON_SEND_PORT,
        gc_PI_CONTROLLER_DAEMON_SEND_PORT,
        gc_OTHER_CONTROLS_DAEMON_SEND_PORT,
        gc_PI_STATUS_DAEMON_SEND_PORT,
        gc_MAC_SWITCH_DAEMON_SEND_PORT,
    ) if ! @ports;

    return @ports;
}

1;
