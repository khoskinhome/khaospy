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

use Sub::Override;
use Data::Dumper;

sub true  { 1 };
sub false { 0 };

sub IN  {"in"};
sub OUT {"out"};

use_ok  ( "Khaospy::ControlPiMCP23017",
            "init_gpio"
        );

my $gpio = {
    i2c_bus  => 0,
    i2c_addr => '0x20',
    portname =>'B',
    portnum  => 5,
};

# Test init
init_gpio(undef,$gpio,OUT);

my $expect = {
    '0' => {
        '0x20' => {
            'b' => [qw/1 1 1 1 1 0 1 1/ ]
        }
    }
};

cmp_deeply(
    Khaospy::ControlPiMCP23017::testing_get_pins_cfg(),
    $expect,
    "pins cfg looks okay"
);

# Test writing to a gpio
$gpio->{portnum} = 0;
Khaospy::ControlPiMCP23017->write_gpio($gpio, true);

my $pins_out = Khaospy::ControlPiMCP23017::testing_get_pins_out_state();
cmp_deeply(
    Khaospy::ControlPiMCP23017::get_pins_array($gpio, $pins_out),
    [qw/1 0 0 0 0 0 0 0/],
    "wrote to pins_out successfully"
);

# Test reading a gpio.
# they should all get init-ed to 1 (true)
# so set one to 0 (false)
my $test_bit = 5;
$gpio->{portnum} = $test_bit;
my $pins_in = Khaospy::ControlPiMCP23017->testing_get_pins_in_state();
Khaospy::ControlPiMCP23017::set_pins_state_array($gpio,$pins_in,false);

for my $bit ( 0..7 ) {
    $gpio->{portnum} = $bit;
    my $expect = $bit == $test_bit ? false : true;
    my $result = Khaospy::ControlPiMCP23017->read_gpio($gpio, $pins_in);
    ok( $result == $expect, "read bit $bit == $expect" );
}

# test the number-to-array and array-to-number conversions :
cmp_deeply(
    Khaospy::ControlPiMCP23017::_num_to_pin_array(255),
    [qw/1 1 1 1 1 1 1 1/],
    "255 splits down to 8 bit array"
);

# The order looks "wrong" in the following tests,
# but it is correct because element 7
# is the most significant "bit" :
cmp_deeply(
    Khaospy::ControlPiMCP23017::_num_to_pin_array(127),
    [qw/1 1 1 1 1 1 1 0/],
    "127 splits down to 8 bit array"
);

cmp_deeply(
    Khaospy::ControlPiMCP23017::_num_to_pin_array(1),
    [qw/1 0 0 0 0 0 0 0/],
    "127 splits down to 8 bit array"
);

cmp_deeply(
    Khaospy::ControlPiMCP23017::_num_to_pin_array(16),
    [qw/0 0 0 0 1 0 0 0/],
    "127 splits down to 8 bit array"
);

ok(
    Khaospy::ControlPiMCP23017::_pin_array_to_num(
        [qw/1 0 0 0 0 0 0 0/]
    ) ==  1,
    "0000 0001 converts to 1"
);

ok(
    Khaospy::ControlPiMCP23017::_pin_array_to_num(
        [qw/0 0 0 0 0 0 0 1/]
    ) ==  128,
    "1000 0000 converts to 128"
);

ok(
    Khaospy::ControlPiMCP23017::_pin_array_to_num(
        Khaospy::ControlPiMCP23017::_num_to_pin_array(128),
    ) ==  128,
    "both pin_array_to_num and num_to_pin_array converting 128"
);




