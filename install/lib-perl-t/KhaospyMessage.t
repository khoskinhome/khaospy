#!perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl/";
# by Karl Kount-Khaos Hoskin. 2015-2016

use Test::More qw/no_plan/;
use Test::Exception;
use Test::Deep;

use Khaospy::Constants qw(
    $JSON
    ON OFF STATUS
    true false
    IN OUT
    $MESSAGES_OVER_SECS_INVALID
);

use Sub::Override;
use Data::Dumper;

use_ok( "Khaospy::Message");

my $tests_live_ok = [
    ON,
    OFF,
    STATUS,
    1,
    [ON,OFF,STATUS],
    [0,3,2,5,0.1],
    {
        dog => ON,
        cat => OFF,
        rat => STATUS,
    },
    {
        dog => 1,
        cat => 5,
        rat => 0.1,
    },
];

for my $test ( @$tests_live_ok ) {
    ok( Khaospy::Message::_validate_action($test), "live ok ");
}

my $tests_die_ok = [
    "some rubbish",
    [0,3,ON,5,OFF],
    ["more rubbish"],
    {
        dog => ON,
        cat => 0.5,
    },
    {
        rat => ON,
        dog => ON,
        rubbish =>"blaah . just die",
    }
];

for my $test ( @$tests_die_ok ) {
    throws_ok { Khaospy::Message::_validate_action($test) }
    qr/.+/,
    " dies ok";
}


