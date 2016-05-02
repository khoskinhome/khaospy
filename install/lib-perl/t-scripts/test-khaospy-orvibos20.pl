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
    $CONTROLS_CONF_FULLPATH
    $ORVIBOS20_CONTROL_TYPE
);

use Khaospy::OrviboS20 qw/signal_control/;


# generate the daemon-runner JSON conf file in perl !

my $json = JSON->new->allow_nonref;

  ## install/bin/khaospy-generate-rrd-graphs.pl:21:my $thermometer_conf = $json->decode( # TODO rm this line

  ## install/lib-perl/Khaospy/Constants.pm:113:        '28-0000066ebc74' => { # TODO rm this line

my $controls = $json->decode(
    slurp ( $CONTROLS_CONF_FULLPATH )
);

print Dumper ( $controls ) ;

#my $host  = '192.168.1.160';
#my $mac = 'AC-CF-23-72-F3-D4';
#test_on_off_status($host,$mac);

for my $control_key ( keys %$controls ) {
    print "##############\n";
    print "Testing $control_key\n";

    my $control = $controls->{$control_key};
    next if lc($control->{type}) ne $ORVIBOS20_CONTROL_TYPE;

    test_on_off_status($control->{host},$control->{mac});

}

sub test_on_off_status {

    my ( $host, $mac ) = @_;

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
        eval { $return = signal_control( $host, $mac, $action ) };

        if ( $@ ) {
            print "FAILED testing ($host, $mac, $action) DIED with return = $return ; $@\n";
        } else {
            if ($test->{$action} eq $return){
                print "PASSED testing ($host, $mac, $action) return = $return\n";
            } else {
                print "FAILED testing ($host, $mac, $action) return = $return\n";
            }
        }
    }
}
