#!/usr/bin/perl

use AnyEvent;
use AnyEvent::MQTT;


my $mqtt = AnyEvent::MQTT->new;



my @w; 

push @w, AnyEvent->timer( 
    after    => 0.1,
    interval => 2,
    cb       => sub { print "timer ...\n" }, 
);


# Net::MQTT



push @w , $mqtt->subscribe(topic => '/karl', callback => sub { my ($topic, $message) = @_; print $topic, ' ', $message, "\n" });

#$cv->recv;




my $quit_program = AnyEvent->condvar;
$quit_program->recv; 


#(@INC contains: /etc/perl /usr/local/lib/x86_64-linux-gnu/perl/5.20.1 /usr/local/share/perl/5.20.1 /usr/lib/x86_64-linux-gnu/perl5/5.20 /usr/share/perl5 /usr/lib/x86_64-linux-gnu/perl/5.20 /usr/share/perl/5.20 /usr/local/lib/site_perl .) at -e line 1.

##(@INC contains: 
#/etc/perl
#/usr/local/lib/x86_64-linux-gnu/perl/5.20.1
#/usr/local/share/perl/5.20.1
#/usr/lib/x86_64-linux-gnu/perl5/5.20
#/usr/share/perl5
#/usr/lib/x86_64-linux-gnu/perl/5.20
#/usr/share/perl/5.20
#/usr/local/lib/site_perl
