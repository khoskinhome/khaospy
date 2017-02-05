#!/usr/bin/perl
use strict; use warnings;
use 5.14.2;

use Data::Dumper;
use AnyEvent;
use Net::MQTT::Constants;
use Net::MQTT::Message;
use IO::Select;
use IO::Socket::INET;
use Time::HiRes;

my $verbose = 0;
my $host = '127.0.0.1';
my $port = 1883;
my $client_id;
my $keep_alive_timer = 20;
my $user_name;
my $password;

my $select_timeout = 0.02;

my @TOPICS = ("karl");

my $socket ;

my $buf = '';
my $mid = 1;
my $next_ping;
my $got_ping_response = 1;

sub mqtt_socket_connect {

    $socket = IO::Socket::INET->new(
        PeerAddr => $host.':'.$port,
        Timeout => $keep_alive_timer,
    ) or die "Socket connect failed: $!\n";

    my @connect = ( message_type => MQTT_CONNECT,
                    keep_alive_timer => $keep_alive_timer,
                    user_name => $user_name,
                    password => $password );

    push @connect, client_id => $client_id if ( defined $client_id );
    send_message( @connect );

    my $msg = read_message() or die "No ConnAck\n";
    #print 'Received: ', $msg->string, "\n" if ($verbose >= 2);

    send_message(
        message_type => MQTT_SUBSCRIBE,
        message_id => $mid++,
        topics => [ map { [ $_ => MQTT_QOS_AT_MOST_ONCE ] } @TOPICS ]
    );

    #print 'Received: ', $msg->string, "\n" if ($verbose >= 2);
    return $socket;
}

$socket = mqtt_socket_connect();

my %w;

sub anyevent_reg {
    return  AnyEvent->io(
        fh   => $socket,
        poll => "r",
        cb   => sub {
            my $msg = read_message();
            if ($msg) {
                if ($msg->message_type == MQTT_PUBLISH) {
                    if ($verbose == 0) {
                        print $msg->topic, " ", $msg->message, "\n";
                    } else {
                        print $msg->string, "\n";
                    }
                } elsif ($msg->message_type == MQTT_PINGRESP) {
                    $got_ping_response = 1;
     #               print 'Received: ', $msg->string, "\n" if ($verbose >= 3);
                } else {
     #               print 'Received: ', $msg->string, "\n" if ($verbose >= 2);
                }
            }

        },
    );
}

$w{mqtt} = anyevent_reg();

$w{timer} = AnyEvent->timer(
    after    => 0.1,
    interval => 10,
    cb       => sub { print "timer ...".time."\n" },
);

say Dumper(\%w);

my $quit_program = AnyEvent->condvar;
$quit_program->recv;


sub send_message {
      #my $socket = shift;
      my $msg = Net::MQTT::Message->new(@_);
#      print 'Sending: ', $msg->string, "\n" if ($verbose >= 2);
      $msg = $msg->bytes;
      syswrite $socket, $msg, length $msg;
#      print dump_string($msg, 'Sent: '), "\n\n" if ($verbose >= 3);
#      $next_ping = Time::HiRes::time + $keep_alive_timer;
}

sub read_message {
    #my ($socket) = @_ ;

    my $buffer = '';
    my $select = IO::Select->new($socket);

    $select->can_read($select_timeout) || return;

    my $bytes = sysread $socket, $buffer, 2048, length $buffer;
    unless ($bytes) {
#        warn "Socket closed ", (defined $bytes ? 'gracefully' : 'error'), "\n";
        if ( defined $bytes ){
            warn "Socket closed gracefully, attempt reconnect ...\n";
            $socket = mqtt_socket_connect();
            delete $w{mqtt};
            $w{mqtt} = anyevent_reg();
            return;
        } else {
            die "Socket closed ERROR\n";
        }
    }
#    print "Receive buffer: ", dump_string($buffer, '   '), "\n\n"
#       if ($verbose >= 3);
    my $mqtt = Net::MQTT::Message->new_from_bytes($buffer, 1);
    return $mqtt if (defined $mqtt);

    return;
}
