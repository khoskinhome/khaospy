package Khaospy::MACSwitchDaemon;
use strict; use warnings;

=pod

=cut

use Try::Tiny;
use Time::HiRes qw/usleep time/;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak confess/;
use Sys::Hostname;

use Nmap::Parser;
use Net::Address::Ethernet qw(
    get_address
    get_addresses
);

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw( ZMQ_PUB );

use Khaospy::Conf::Controls qw(
    get_controls_conf
    get_controls_conf_for_host
);

use Khaospy::Conf::Global qw(
    gc_MAC_SWITCH_DAEMON_SEND_PORT
);

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    $JSON

    ON OFF
    true false

    $MAC_SWITCH_CONTROL_TYPE
    $MAC_SWITCH_DAEMON_TIMER
    $MAC_SWITCH_NMAP_ARGS
    $NMAP_EXECUTABLE
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogextra klogdebug
);

use Khaospy::Utils qw(
    get_hashval
);

# use Khaospy::ZMQAnyEvent qw/ zmq_anyevent /;
use zhelpers;

our @EXPORT_OK = qw( run_mac_switch_daemon );

my $zmq_publisher;
my $controls;
my $np;

my $mac_to_control_name = {};

my $control_name_current_state = {};

my $nmap_args;
my $nmap_iprange;

sub run_mac_switch_daemon {
    # TODO do a failure if this daemon isn't run as root.
    # ( sudo is needed for the nmap )
    my ($opts) = @_;
    $opts = {} if ! $opts;

    $nmap_iprange = $opts->{nmap_iprange};
    klogfatal "MAC Switch daemon needs the -i --ip --iprange CLI option to be defined"
        if ! $nmap_iprange;

    $nmap_args    = $opts->{nmap_args}    || $MAC_SWITCH_NMAP_ARGS;
    my $timer     = $opts->{timer}        || $MAC_SWITCH_DAEMON_TIMER;

    klogstart "MAC Switch daemon START";

    $np = Nmap::Parser->new();

    $controls = get_controls_conf();

    for my $control_name ( keys %$controls ){
        my $control = get_hashval($controls,$control_name);

        # TODO : the getting a hash of controls of all one control-type could
        # go in Khaospy::Conf::Controls as a utility sub
        if (get_hashval($control,'type') eq $MAC_SWITCH_CONTROL_TYPE){
            $mac_to_control_name->{get_hashval($control,'mac')} = {
                control_name => $control_name,
                control      => $control,
            };
        }
    }

    $zmq_publisher  = zmq_socket($ZMQ_CONTEXT, ZMQ_PUB);
    my $pub_to_port = "tcp://*:".gc_MAC_SWITCH_DAEMON_SEND_PORT;
    zmq_bind( $zmq_publisher, $pub_to_port );

    my @w;

    push @w, AnyEvent->timer(
        after    => 0.1, # TODO. MAGIC NUMBER . should be in Constants.pm or a json-config. dunno. but not here.
        interval => $timer,
        cb       => \&timer_cb
    );

    my $quit_program = AnyEvent->condvar;
    $quit_program->recv;
}

sub timer_cb {
    kloginfo "Scanning for MAC state changes ... (in timer)";

    $np->parsescan( $NMAP_EXECUTABLE, $nmap_args, $nmap_iprange );

    my $not_found_ctrls = { # maps control_name => mac
        map { get_hashval(get_hashval($mac_to_control_name,$_),'control_name') => $_ }
        keys %$mac_to_control_name
    };

    for my $h ( $np->all_hosts('up') ){

        my $hip  = $h->ipv4_addr();
        my $hmac = $h->mac_addr();

        # The host this script is on will get nmap-ed but nmap will not supply
        # the MAC address. ( hence Net::Address::Ethernet->get_address )
        $hmac = _get_mac_if_ip_is_this_host($hip) if ! $hmac;

        if ( $hmac ){
            my $mtcn = $mac_to_control_name->{$hmac};
            if ( $mtcn ) { # mac found in control config.
                my $control_name = get_hashval($mtcn,'control_name');
                delete $not_found_ctrls->{$control_name};
                if ( ! exists $control_name_current_state->{$control_name}
                    || $control_name_current_state->{$control_name} ne ON
                ){
                    kloginfo "$control_name with MAC $hmac is ON";
                    my $send_msg = {
                        control_name       => $control_name,
                        request_epoch_time => time,
                        request_host       => hostname,
                        current_state      => ON,
                        action             => ON,
                        mac_addr           => $hmac,
                        ip_addr            => $hip,
                    };
                    my $json_msg = $JSON->encode($send_msg);
                    zhelpers::s_send( $zmq_publisher, "$json_msg" );
                    $control_name_current_state->{$control_name} = ON;
                }
            } else { # mac not found in control config
                klogerror "MAC $hmac not found in control config";
            }
        }
    }

    for my $control_name_nf ( keys %$not_found_ctrls ){
        my $hmac = get_hashval($not_found_ctrls,$control_name_nf);
        if ( ! exists $control_name_current_state->{$control_name_nf}
            || $control_name_current_state->{$control_name_nf} ne OFF
        ){
            kloginfo "$control_name_nf with MAC $hmac is OFF";
            my $send_msg = {
                control_name       => $control_name_nf,
                request_epoch_time => time,
                request_host       => hostname,
                current_state      => OFF,
                action             => OFF,
                mac_addr           => $hmac,
                ip_addr            => undef,
            };
            my $json_msg = $JSON->encode($send_msg);
            zhelpers::s_send( $zmq_publisher, "$json_msg" );
            $control_name_current_state->{$control_name_nf} = OFF;
        }
    }
}

sub _get_mac_if_ip_is_this_host {
    my ($hip) = @_;

    # will probably not work on multi NIC-ed machines :
    # ( I haven't tested it )
    for my $adapter ( get_addresses ) {
        if ( $adapter->{sEthernet} eq get_address
            and $adapter->{sIP} eq $hip
        ) {
            return $adapter->{sEthernet};
        }
    }
    return;
}

1;
