#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use JSON;
use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw/slurp/;
use Khaospy::Constants qw(
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $KHAOSPY_ORVIBO_S20_CONF_FULLPATH
);

# generate the daemon-runner JSON conf file in perl !

my $json = JSON->new->allow_nonref;

# 2015-12-25 . This is the current script for polling thermometers and switching the orvibo S20s.

my $thermometer_conf = $json->decode(
    slurp ( $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH )
);

  ## install/bin/khaospy-generate-rrd-graphs.pl:21:my $thermometer_conf = $json->decode( # TODO rm this line

  ## install/lib-perl/Khaospy/Constants.pm:113:        '28-0000066ebc74' => { # TODO rm this line


my $controls = $json->decode(
    slurp ( $KHAOSPY_ORVIBO_S20_CONF_FULLPATH )
);

#
# Based on
#  http://forums.ninjablocks.com/index.php?
#   p=/discussion/2931/aldi-remote-controlled-power-points-5-july-2014/p1
#  and
#   http://pastebin.ca/2818088
#  and
#   https://github.com/franc-carter/bauhn-wifi/blob/master/bauhn.pl
#
# Tuned for Orvibo S20 by Branislav Vartik

use IO::Socket;
use IO::Select;
use Data::Dumper;
use Net::Ping;
use Time::HiRes qw/usleep/;

my $debug = 0; # Change this to 0 to avoid debug messages
my $port = 10000;

my $fbk_preamble = pack('C*', (0x68,0x64,0x00,0x1e,0x63,0x6c));
my $ctl_preamble = pack('C*', (0x68,0x64,0x00,0x17,0x64,0x63));
my $ctl_on       = pack('C*', (0x00,0x00,0x00,0x00,0x01));
my $ctl_off      = pack('C*', (0x00,0x00,0x00,0x00,0x00));
my $twenties     = pack('C*', (0x20,0x20,0x20,0x20,0x20,0x20));
my $onoff        = pack('C*', (0x68,0x64,0x00,0x17,0x73,0x66));
my $subscribed   = pack('C*', (0x68,0x64,0x00,0x18,0x63,0x6c));

sub findS20($$)
{

    my ($mac, $ip ) = @_;

    my $s20;
    my $reversed_mac = scalar(reverse($mac));
    my $subscribe    = $fbk_preamble.$mac.$twenties.$reversed_mac.$twenties;

    my $socket = IO::Socket::INET->new(Proto=>'udp', LocalPort=>$port, Broadcast=>1) ||
                     die "Could not create listen socket: $!\n";
    $socket->autoflush();
    my $select = IO::Select->new($socket) ||
                     die "Could not create Select: $!\n";

#    my $to_addr = sockaddr_in($port, INADDR_BROADCAST);
    my $iaddr = inet_aton($ip) || die 'Unable to resolve';
    my $to_addr = sockaddr_in($port, $iaddr);


    $socket->send($subscribe, 0, $to_addr) ||
        die "Send error: $!\n";

    my $n = 1;
    while($n <= 3) {

        print "DEBUG: Waiting for status $n\n" if $debug;
        my @ready = $select->can_read(1);
        foreach my $fh (@ready) {
            my $packet;
            my $from = $socket->recv($packet,1024) || die "recv: $!";
            if ((substr($packet,0,6) eq $subscribed) && (substr($packet,6,6) eq $mac)) {
                my ($port, $iaddr) = sockaddr_in($from);
                $s20->{mac}      = $mac;
                $s20->{saddr}    = $from;
                $s20->{socket}   = $socket;
                $s20->{on}       = (substr($packet,-1,1) eq chr(1));
                return $s20;
            }
        }
        $n++;
    }
    close($socket);
    return undef;
}

sub controlS20($$){
    my ($s20,$action) = @_;

    for(my $n=1; $n<=3; $n++) {
        print "DEBUG: Waiting for confirmation $n\n" if $debug;
        return if _controlS20($s20, $action) ;
    }
    print STDERR "Could not change S20 to $action\n";

}

sub _controlS20($$)
{
    my ($s20,$action) = @_;

    my $mac = $s20->{mac};

    if (!$mac){
        # TODO raise an exception
        print STDERR "can't _controlS20 with undefined $mac\n";
        return;
    }

    if ($action eq "on") {
        $action   = $ctl_preamble.$mac.$twenties.$ctl_on;
    }
    if ($action eq "off") {
        $action   = $ctl_preamble.$mac.$twenties.$ctl_off;
    }

    my $select = IO::Select->new($s20->{socket}) ||
                     die "Could not create Select: $!\n";
    my $n = 0;
    while($n < 2) {
        $s20->{socket}->send($action, 0, $s20->{saddr}) ||
            die "Send error: $!\n";

        my @ready = $select->can_read(0.5);
        foreach my $fh (@ready) {
            my $packet;
            my $from = $s20->{socket}->recv($packet,1024) ||
                           die "recv: $!";
            my @data = unpack("C*", $packet);
            my @packet_mac = @data[6..11];
            if (($onoff eq substr($packet,0,6)) && ($mac eq substr($packet,6,6))) {
                return 1;
            }
        }
        $n++;
    }
    return 0;
}

sub signal_all_controls {
    my ($action) = @_;

    print "\n### signal all controls with $action ####\n";
    for my $controlname ( sort keys %$controls ) {
        print "$controlname is ".signal_control( $controlname, $action )."\n";
    }
}

=head1 signal_control

on success returns "on" or "off"

on error will raise on of the following exceptions :

=cut

sub signal_control {
    my ( $controlname, $action ) = @_;

    usleep(100000);

    my $control = $controls->{$controlname};
    if ( ! $control ) {
        # TODO should raise an exception
        return "control-not-found-in-config";
    }

    my $ip = $control->{ip};
    my $n = 1;
    my $p = Net::Ping->new('icmp', 1);
    do {
            if ( $n == 5 ) {
                # TODO should raise an exception
                return "ip-unreachable";
            }
            $n++;
    } until ($p->ping($ip));
    $p->close();

    my $mac = get_packed_mac($control->{mac});
    if (! $mac ) {
        # TODO should raise an exception
        return "config-invalid-mac";
    }

    my $s20 = findS20( $mac, $ip );

    usleep(100000);

    $action = lc($action);
    if ($action eq 'status'){
        return $s20->{on} ? "on" : "off";
    } elsif ( $action eq 'on' or $action eq 'off' ){
        controlS20($s20, $action);
        return $action;
    } else {
        # TODO should raise an exception
        return "failed-to-send-action";
    }
}

sub get_packed_mac {
    # using the XX-XX-XX-XX-XX-XX or XX:XX:XX:XX:XX:XX notation.
    my ($p_mac) = @_;

    $p_mac =~ s/:/-/g;
    my @mac = split('-', $p_mac);

    # TODO should raise an exception
    return if ($#mac != 5) ;

    @mac = map { hex("0x".$_) } @mac;
    my $mac = pack('C*', @mac);

    return $mac;
}


#############################################################
# getting the temperatures.

# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_SUB ZMQ_SUBSCRIBE ZMQ_RCVMORE ZMQ_FD);

my $quit_program = AnyEvent->condvar;

my $context = zmq_init();

my $w = [];
for my $host ( qw/piloft pioldwifi/ ) {

    my $subscriber = zmq_socket($context, ZMQ_SUB);
    zmq_connect($subscriber, "tcp://$host:5001");
    zmq_setsockopt($subscriber, ZMQ_SUBSCRIBE, 'oneWireThermometer');

    my $fh = zmq_getsockopt( $subscriber, ZMQ_FD );

    push @$w , anyevent_io( $fh, $subscriber);
};

$quit_program->recv;

sub anyevent_io {
    my ( $fh, $subscriber ) = @_;
    return AnyEvent->io(
        fh   => $fh,
        poll => "r",
        cb   => sub {
            while ( my $recvmsg = zmq_recvmsg( $subscriber, ZMQ_RCVMORE ) ) {
                process_thermometer_msg ( zmq_msg_data($recvmsg) );

            }
        },
    );
}

sub process_thermometer_msg {
    my ($msg) = @_;
    my ($topic, $msgdata) = $msg =~ m/(.*?)\s+(.*)$/;

    my $msg_decoded = $json->decode( $msgdata );

    my $owaddr    = $msg_decoded->{OneWireAddress};
    my $curr_temp = $msg_decoded->{Celsius};

    my $tc   = $thermometer_conf->{$owaddr};

    if ( ! defined $tc ) {
        print "One-wire address $owaddr isn't in "
            ."$KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH config file\n";
        return;
    }

    my $name = $tc->{name}
        || die "name isn't defined for $owaddr in "
            ."$KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH ";

    print "##########\n";
    print "$name : $owaddr : Celsius = $curr_temp.\n";

    my $turn_on_command    = $tc->{turn_on_command} || '';
    my $turn_off_command   = $tc->{turn_off_command} || '';
    my $get_status_command = $tc->{get_status_command} || '';
    my $upper_temp         = $tc->{upper_temp} || '';
    my $lower_temp         = $tc->{lower_temp} || '';

    if ( ! $turn_on_command && ! $turn_off_command && ! $get_status_command
        && ! $upper_temp && ! $lower_temp
    ){
        print "    Nothing configured for this thermometer\n";
        return;
    }

    if ( ! $turn_on_command || ! $turn_off_command || ! $get_status_command
        || ! $upper_temp || ! $lower_temp
    ){
        print "    Not all the parameters are configured for this thermometer\n";
        print "    See the config file $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH\n";
        print "    Cannot operate this control.\n";
        return;
    }

    if ( $upper_temp <= $lower_temp ) {
        print "    Broken temperature range in $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH config.\n";
        print "    (Upper) $upper_temp <= (Lower) $lower_temp\n";
        print "    Upper temperature must be greater than the lower temperature\n";
        return;
    }

    if ( $curr_temp > $upper_temp ){
        print "    turn_off_command : ".$turn_off_command." : (Current) $curr_temp > (Upper) $upper_temp\n";

    }
    elsif ( $curr_temp < $lower_temp ){
        print "    turn_on_command : ".$turn_on_command." : (Current) $curr_temp < (Lower) $lower_temp\n";


    } else {
        print "    Current temperate is in correct range : (Lower) $lower_temp < (Current) $curr_temp < (Upper) $upper_temp\n";
    }

# TODO get the dispatching to an orviboS20 command working.
# TODO get the dispatching to the i2c connected rad-controllers.
#
#        if ( $hc->{orviboS20_rad_hostname} ) {
#            print "$name : Switch off ".$hc->{orviboS20_rad_hostname}."\n";
#            print "$name : signal_control = ".signal_control($hc->{orviboS20_rad_hostname},"off")."\n";
#        } else {
#            print "$name : Nothing configured to switch off\n";
#        }
#
#        if ( $hc->{orviboS20_rad_hostname} ) {
#            print "$name : Switch on ".$hc->{orviboS20_rad_hostname}."\n";
#            print "$name : signal_control = ".signal_control($hc->{orviboS20_rad_hostname},"on")."\n";
#        } else {
#            print "$name : Nothing configured to switch on\n";
#        }

}
