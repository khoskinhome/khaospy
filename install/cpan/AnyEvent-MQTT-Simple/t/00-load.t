

###### #!perl -T
use strict; use warnings;
use Data::Dumper;
use Test::More;
use Test::Exception;

use FindBin;
FindBin::again();

use lib "$FindBin::Bin/../lib";


BEGIN {
    use_ok( 'AnyEvent::MQTT::Simple' ) || BAIL_OUT("Can't use AnyEvent::MQTT::Simple\n");
    use_ok( 'AnyEvent' ) || BAIL_OUT("Can't use AnyEvent\n");
}

diag( "Testing AnyEvent::MQTT::Simple $AnyEvent::MQTT::Simple::VERSION, Perl $], $^X" );

my $ams = AnyEvent::MQTT::Simple->new();

my $ams2 = AnyEvent::MQTT::Simple->new(
        topics => 'karl',
        
    );


$ams2->publish( message => " GOT A MESSAGE !" );



#$ams->subscribe(
#    callback => sub {
#        diag("received ".Dumper(\@_));
###        $ams2->publish(" GOT A MESSAGE !" );
#
#    },
#    topics  => 'karl',
#    timeout => 10,
#);

#$socket = mqtt_socket_connect();
#
my %w;
#
#$w{mqtt} = anyevent_reg();
#
$w{timer} = AnyEvent->timer(
    after    => 0.1,
    interval => 10,
    cb       => sub { print "timer ...".time."\n" },
);
#
#say Dumper(\%w);
#
my $quit_program = AnyEvent->condvar;
$quit_program->recv;

#                if ($msg->message_type == MQTT_PUBLISH) {
#                    if ($verbose == 0) {
#                        print $msg->topic, " ", $msg->message, "\n";
#                    } else {
#                        print $msg->string, "\n";
#                    }
#                } elsif ($msg->message_type == MQTT_PINGRESP) {
#                    $got_ping_response = 1;
#     #               print 'Received: ', $msg->string, "\n" if ($verbose >= 3);
#                } else {
#     #               print 'Received: ', $msg->string, "\n" if ($verbose >= 2);
#                }



done_testing();
