#!/usr/bin/perl -w
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

use strict;
use IO::Socket;
use IO::Select;
use Data::Dumper;
use Net::Ping;
use Time::HiRes qw/usleep/;

use ZMQ::LibZMQ3;

my $debug = 0; # Change this to 0 to avoid debug messages
my $port = 10000;

# AC-CF-23-72-F3-D4 ameliaradiator  192.168.1.160
# AC-CF-23-72-D1-FE alisonradiator  192.168.1.161
# AC-CF-23-8D-A4-8E dinningroomrad  192.168.1.162
# AC-CF-23-8D-7E-D2 karlradiator    192.168.1.163
# AC-CF-23-8D-3B-96 frontroomrad    192.168.1.164

# TODO find a way of using the host name from /etc/hosts to get the ip and mac. 

my $controls = {
    alisonrad       => { ip => '192.168.1.161', mac => 'AC:CF:23:72:D1:FE' },
#    ameliarad       => { ip => '192.168.1.160', mac => 'AC-CF-23-72-F3-D4' },
    karlrad         => { ip => '192.168.1.163', mac => 'AC-CF-23-8D-7E-D2' },
    dinningroomrad  => { ip => '192.168.1.162', mac => 'AC-CF-23-8D-A4-8E' },
    frontroomrad    => { ip => '192.168.1.164', mac => 'AC-CF-23-8D-3B-96' },
};


############################
#/sys/bus/w1/devices/28-00000670596d/w1_slave  bathroom
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-00000670596d", "EpochTime": 1448811213.284851, "Celsius": 21.812}

#/sys/bus/w1/devices/28-0000066ebc74/w1_slave  alison
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-0000066ebc74", "EpochTime": 1448811214.115049, "Celsius": 20.562}

#/sys/bus/w1/devices/28-021463277cff/w1_slave  loft
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-021463277cff", "EpochTime": 1448811214.94498, "Celsius": 14.187}

#/sys/bus/w1/devices/28-021463423bff/w1_slave  landing
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-021463423bff", "EpochTime": 1448811215.774984, "Celsius": 20.062}

#/sys/bus/w1/devices/28-0214632d16ff/w1_slave  amelia
#{"HomeAutoClass": "oneWireThermometer", "OneWireAddress": "28-0214632d16ff", "EpochTime": 1448811216.615052, "Celsius": 20.812}
#


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

signal_all_controls("off");
signal_all_controls("status");
for my $i ( 0..1) {
    signal_control("karlrad","on");
    signal_control("karlrad","off");
}

signal_all_controls("status");

#signal_control("karlrad","on");




