package Khaospy::ControlPiMCP23017;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/confess/;
use Time::HiRes qw/time/;

use Khaospy::Constants qw(
    $PI_I2C_GET
    $PI_I2C_SET
    IN $IN OUT $OUT
    true false
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

use Khaospy::Utils qw(
    get_hashval
);

our @EXPORT_OK = qw(
    init_mcp23017
    poll_mcp23017
    init_gpio
    read_gpio
    write_gpio
);

#=pod
#        my $switch_state = qx{i2cget -y $i2c_bus_y 0x20 0x12};
#=cut

#=pod
# $mcp23017_pins_[config|state] = {
#    <i2c_bus> => {
#        <i2c_addr> => {
#            <port_a|port_b> => [
#                bit0,
#                bit1,
#                ....
#                bit7
#            ]
#             <port_a_mask> ???
#        }
#    },
#
# }
#
# mcp_OLAT | mcp_GPIO | mcp_IODIR = {
#     <i2c_bus> => {
#         <i2c_addr> => {
#                 val =>  integer,
#                 time => epoch_secs # since last updated. INs read, OUTs written.
#             }
#         }
#     }
#
# gpio = { # something like :
#    i2c_bus  => 0,
#	 i2c_addr => '0x20',
#	 portname =>'b',
#	 portnum  => 1,
# };


#=cut

# IODIR, GPIO and OLAT are terms used on the Microchip's MCP23017 data-sheet

# IODIR A/B are used to set the direction of the gpio pin
# 0 for output, 1 for input. ( i.e. 0xFF is all input )
my $IODIR = { a => '0x00', b => '0x01' };

# GPIO A/B are used to get the input on a gpio port
my $GPIO  = { a => '0x12', b => '0x13' };

# OLAT A/B are used to switch on and off the outputs on a gpio port.
my $OLAT  = { a => '0x14', b => '0x15' };

my $mcp_IODIR = {};
my $mcp_GPIO  = {};
my $mcp_OLAT  = {};

my $pins_cfg       = {}; # used by IODIR[A|B]
my $pins_out_state = {}; # used by OLAT[A|B]
my $pins_in_state  = {}; # used by GPIO[A|B]

# needed for testing.
sub testing_get_pins_cfg       { $pins_cfg }
sub testing_set_pins_cfg       { $pins_cfg = $_[0] }
sub testing_get_pins_in_state  { $pins_in_state }
sub testing_set_pins_in_state  { $pins_in_state = $_[0] }
sub testing_get_pins_out_state { $pins_out_state }
sub testing_set_pins_out_state { $pins_out_state = $_[0] }

sub init_gpio {
    my ($class, $gpio, $IN_OUT ) = @_;
    # inits a single gpio pin
    _init_pins( $gpio, $pins_cfg      , $IN_OUT, true );
    _init_pins( $gpio, $pins_in_state ,undef   , true );
    _init_pins( $gpio, $pins_out_state,undef   , false );
}

sub _init_pins {
    my ( $gpio, $pins_i, $IN_OUT, $default_bit ) = @_;

    confess "programming error. default_bit ($default_bit) not set correctly "
        if ! defined $default_bit || $default_bit !~ /^[01]$/g;

    $pins_i->{$gpio->{i2c_bus}} = {}
        if ! exists $pins_i->{get_hashval($gpio, 'i2c_bus')};
    my $i2c_bus_rh = $pins_i->{$gpio->{i2c_bus}};

    $i2c_bus_rh->{$gpio->{i2c_addr}} = {}
        if ! exists $i2c_bus_rh->{get_hashval($gpio, 'i2c_addr')};
    my $i2c_addr_rh = $i2c_bus_rh->{$gpio->{i2c_addr}};

    $gpio->{portname} = lc(get_hashval($gpio, 'portname'));
    # Default of 11111111 0xff , so the IODIR defaults to input.
    # this is electronically safer for the MCP23017
    $i2c_addr_rh->{lc($gpio->{portname})} = [ map { $default_bit } 0..7 ]
        if ! exists $i2c_addr_rh->{$gpio->{portname}};

    return if ! defined $IN_OUT;

    klogfatal "Can only set a Pi MCP23017 mode ($IN_OUT) to 'in' or 'out'"
        if $IN_OUT ne IN and $IN_OUT ne OUT;

    $i2c_addr_rh->{$gpio->{portname}}[ get_hashval($gpio,'portnum')]
        = ( $IN_OUT eq IN ) ? true : false ;
}

sub init_mcp23017 {

    print Dumper ( $pins_cfg );
    # TODO actually push the pin config to the chip

}

sub poll_mcp23017 {
    # TODO reads the INs , writes the OUTs

}

sub get_pins_i_name {
    my ( $pins_i ) = @_;
    return 'pins_cfg'       if $pins_i == $pins_cfg;
    return 'pins_in_state'  if $pins_i == $pins_in_state;
    return 'pins_out_state' if $pins_i == $pins_out_state;
    return 'unknown-pins-datastructure';
}

sub get_pins_array {
    my ($gpio, $pins_i) = @_;

    klogfatal get_pins_i_name($pins_i)." doesn't have i2c_bus set"
        if ! exists $pins_i->{get_hashval($gpio, 'i2c_bus')};
    my $i2c_bus_rh = $pins_i->{$gpio->{i2c_bus}};

    klogfatal get_pins_i_name($pins_i)." doesn't have i2c_addr set"
        if ! exists $i2c_bus_rh->{get_hashval($gpio, 'i2c_addr')};
    my $i2c_addr_rh = $i2c_bus_rh->{$gpio->{i2c_addr}};

    $gpio->{portname} = lc(get_hashval($gpio, 'portname'));
    klogfatal get_pins_i_name($pins_i)." doesn't have portname set"
        if ! exists $i2c_addr_rh->{$gpio->{portname}};
    my $array_ra = $i2c_addr_rh->{$gpio->{portname}};

    return $array_ra;
}

sub set_pins_state_array {
    my ( $gpio, $pins_i, $new_state ) = @_;

    klogfatal "new_state ($new_state) isn't 1 or 0"
        if $new_state != true and $new_state != false;

    # Should never need to set the pins_cfg after init.
    klogfatal get_pins_i_name($pins_i)." is not settable"
        if $pins_i != $pins_in_state
            and $pins_i != $pins_out_state;

    get_pins_array($gpio, $pins_i)->[ get_hashval($gpio,'portnum') ]
        = $new_state;
}

sub read_gpio {
    my ( $class, $gpio ) = @_;

    return get_pins_array( $gpio, $pins_in_state )
        ->[ get_hashval($gpio, 'portnum') ];
}

sub write_gpio {
    my ( $class, $gpio, $new_state ) = @_;
    set_pins_state_array($gpio, $pins_out_state, $new_state);
}

sub _pin_array_to_num {
    my ( $array ) = @_;

    klogfatal "Array doesn't have 8 bits for gpio, or a bit is not either 1 or 0",
        $array if @$array != 8 || grep { $_ != true and $_ != false } @$array;

    return oct("0b".join( "", reverse @$array));
}

sub _num_to_pin_array {
    my ( $num ) = @_;

    klogfatal "number is not between 0 and 255"
        if $num < 0 || $num > 255;

    return [ reverse split ( //, sprintf("%08b", $num ) )];

}

1;

