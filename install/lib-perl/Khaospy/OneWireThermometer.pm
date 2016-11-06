package Khaospy::OneWireThermometer;
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
use ZMQ::Constants qw( ZMQ_PUB );

use Khaospy::Conf::Controls qw(
    get_control_name_for_one_wire
);

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON

    $ONE_WIRE_SENSOR_DIR
    $ONE_WIRE_DAEMON_PERL_PORT
    $ONE_WIRE_SENDER_PERL_TIMER
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

use Khaospy::Utils qw(slurp);

use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;
use zhelpers;

our @EXPORT_OK = qw(
    run_one_wire_thermometer_daemon
);

my $zmq_publisher;

sub run_one_wire_thermometer_daemon {
    my ($opts) = @_;
    $opts = {} if ! $opts;

    klogstart "One Wire Thermometer (perl) daemon START";

    # TODO do a failure if this daemon isn't run as root.
    # ( needed for the modprobe-s )

    system('sudo modprobe w1-gpio');
    system('sudo modprobe w1-therm');

    chdir($ONE_WIRE_SENSOR_DIR) || die "can't cd to $ONE_WIRE_SENSOR_DIR\n";

    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:$ONE_WIRE_DAEMON_PERL_PORT";
    zmq_bind( $zmq_publisher, $pub_to_port );

    my @w;

    push @w, AnyEvent->timer(
        after    => 0.1, # TODO. MAGIC NUMBER . should be in Constants.pm or a json-config. dunno. but not here.
        interval => $ONE_WIRE_SENDER_PERL_TIMER,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {
    klogdebug "in timer ";

    for my $onewire_addr (<*> ){
        next if $onewire_addr !~ /^\d\d/;
        my @data = split /\n/, slurp( "$onewire_addr/w1_slave" );

        if ( $data[0] !~ /YES$/ ) {
            klogerror "Reading $onewire_addr";
            next;
        }

        my $temp;
        if ( ($temp) = $data[1] =~ /t=(\-?\d{2,})/ ){
            $temp = $temp/1000;
        } else {
            klogerror "Extracting temp from $onewire_addr";
            next;
        }

        my $control_name
            = get_control_name_for_one_wire($onewire_addr)
                || "UNCONFIGURED CONTROL";

        kloginfo "$control_name : $onewire_addr = $temp \n";

        my $send_msg = {
            control_name => $control_name,
            request_epoch_time => time,
            current_value => $temp,
            onewire_addr  => $onewire_addr,
        };

        my $json_msg = $JSON->encode($send_msg);
        zhelpers::s_send( $zmq_publisher, "$json_msg" );
    }
}

1;
