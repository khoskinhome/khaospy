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
    $KHAOSPY_ORVIBO_S20_CONF_FULLPATH
);

use Khaospy::OrviboS20 qw/signal_control/;


# generate the daemon-runner JSON conf file in perl !

my $json = JSON->new->allow_nonref;

  ## install/bin/khaospy-generate-rrd-graphs.pl:21:my $thermometer_conf = $json->decode( # TODO rm this line

  ## install/lib-perl/Khaospy/Constants.pm:113:        '28-0000066ebc74' => { # TODO rm this line

my $controls = $json->decode(
    slurp ( $KHAOSPY_ORVIBO_S20_CONF_FULLPATH )
);

print Dumper ( $controls ) ;

#my $ip  = '192.168.1.160';
#my $mac = 'AC-CF-23-72-F3-D4';
#test_on_off_status($ip,$mac);

for my $control_key ( keys %$controls ) {
    print "##############\n";
    print "Testing $control_key\n";

    my $control = $controls->{$control_key};

    test_on_off_status($control->{ip},$control->{mac});

}


sub test_on_off_status {

    my ( $ip, $mac ) = @_;

    my $tests  = [
        {on     => "on"},
        {status => "on"},
        {status => "on"},
        {off    => "off"},
        {status => "off"},
        {status => "off"},
        {on     => "on"},
        {off    => "off"},
        {status => "off"},
        {on     => "on"},
        {off    => "off"},
        {on     => "on"},
        {status => "on"},
        {off    => "off"},
    ];

    for my $test ( @$tests ) {
        my ( $action ) = keys %$test;

        my $return;
        eval { $return = signal_control( $ip, $mac, $action ) };

        if ( $@ ) {
            print "FAILED testing ($ip, $mac, $action) DIED with return = $return ; $@\n";
        } else {
            if ($test->{$action} eq $return){
                print "PASSED testing ($ip, $mac, $action) return = $return\n";
            } else {
                print "FAILED testing ($ip, $mac, $action) return = $return\n";
            }
        }
    }
}
