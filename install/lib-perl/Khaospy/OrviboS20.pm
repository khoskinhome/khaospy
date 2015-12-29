package Khaospy::OrviboS20;
use strict;
use warnings;

use Exporter qw/import/;
our @EXPORT_OK = qw( signal_control );

use IO::Socket;
use IO::Select;
use Data::Dumper;
use Net::Ping;
use Time::HiRes qw/usleep/;

# ATTRIBUTION
#
# Based on
#  http://forums.ninjablocks.com/index.php?p=/discussion/2931/aldi-remote-controlled-power-points-5-july-2014/p1
#  and
#   http://pastebin.ca/2818088
#  and
#   https://github.com/franc-carter/bauhn-wifi/blob/master/bauhn.pl
#
# Tuned for Orvibo S20 by Branislav Vartik
#
# Put into a perl module by Karl Hoskin.

my $debug = 0; # Change this to 0 to avoid debug messages
my $port = 10000;

my $fbk_preamble = pack('C*', (0x68,0x64,0x00,0x1e,0x63,0x6c));
my $ctl_preamble = pack('C*', (0x68,0x64,0x00,0x17,0x64,0x63));
my $ctl_on       = pack('C*', (0x00,0x00,0x00,0x00,0x01));
my $ctl_off      = pack('C*', (0x00,0x00,0x00,0x00,0x00));
my $twenties     = pack('C*', (0x20,0x20,0x20,0x20,0x20,0x20));
my $onoff        = pack('C*', (0x68,0x64,0x00,0x17,0x73,0x66));
my $subscribed   = pack('C*', (0x68,0x64,0x00,0x18,0x63,0x6c));


=head1 signal_control

on success returns "on" or "off"

on error will raise on of the following exceptions :

=cut

sub signal_control {
    my ( $host, $p_mac, $action ) = @_;

    # TODO , must be a better way, I don't like this usleep :
    usleep(100000);

    my $n = 1;
    my $p = Net::Ping->new('icmp', 1);
    do {
        if ( $n == 5 ) {
            die "ip-unreachable $host";
        }
        $n++;
    } until ($p->ping($host));
    $p->close();

    my $pack_mac = get_packed_mac($p_mac);
    if (! $pack_mac ) {
        die "config-invalid-mac $p_mac";
    }

    my $s20 = findS20( $pack_mac, $host );

    # TODO , must be a better way, I don't like this usleep :
    usleep(100000);

    $action = lc($action);
    if ($action eq 'status'){
        return $s20->{on} ? "on" : "off";
    } elsif ( $action eq 'on' or $action eq 'off' ){
        controlS20($s20, $action);
        return $action;
    } else {
        die "failed-to-send-action";
    }
}

sub findS20($$)
{

    my ($mac, $host ) = @_;

    my $s20;
    my $reversed_mac = scalar(reverse($mac));
    my $subscribe    = $fbk_preamble.$mac.$twenties.$reversed_mac.$twenties;

    my $socket = IO::Socket::INET->new(Proto=>'udp', LocalPort=>$port, Broadcast=>1) ||
                     die "Could not create listen socket: $!\n";
    $socket->autoflush();
    my $select = IO::Select->new($socket) ||
                     die "Could not create Select: $!\n";

    # my $to_addr = sockaddr_in($port, INADDR_BROADCAST);
    my $iaddr = inet_aton($host) || die 'Unable to resolve';
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



sub get_packed_mac {
    # using the XX-XX-XX-XX-XX-XX or XX:XX:XX:XX:XX:XX notation for mac.
    my ($p_mac) = @_;

    $p_mac =~ s/:/-/g;
    my @mac = split('-', $p_mac);

    # TODO should raise an exception
    return if ($#mac != 5) ;

    @mac = map { hex("0x".$_) } @mac;
    return pack('C*', @mac);
}


1;
