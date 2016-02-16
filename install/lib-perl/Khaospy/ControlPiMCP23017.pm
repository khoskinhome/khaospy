package Khaospy::ControlPiMCP23017;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/confess/;
use Time::HiRes qw/time/;

use Clone qw/clone/;

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
#$mcp23017_pins_[config|state] = {
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
#}
#
#    mcp_OLAT | mcp_GPIO | mcp_IODIR = {
#        <i2c_bus> => {
#            <i2c_addr> => {
#                    val =>  integer,
#                    time => epoch_secs # since last updated. INs read, OUTs written.
#                }
#            }
#        }
#

#=cut

# IODIR, GPIO and OLAT are terms used on the Microchip's MCP23017 data-sheet

# IODIR A/B are used to set the direction of the gpio pin
# 0 for output, 1 for input. ( i.e. 0xFF is all input )
my $IODIR = { a => '0x00', b => '0x01' };

# GPIO A/B are used to get the input on a gpio port
my $GPIO  = { a => '0x12', b => '0x13' };

# OLAT A/B are used to switch on and off the outputs on a gpio port.
my $OLAT  = { a => '0x14', b => '0x15' };

my $mcp_IODIR ={};
my $mcp_GPIO = {};
my $mcp_OLAT = {};

my $pins_cfg   = {};

my $pins_state = {};

sub get_pins_cfg {
    # needed for testing.
    return clone $pins_cfg;
}

sub get_pins_state {
    # needed for testing.
    return clone $pins_state;
}

sub init_gpio {
    my ($class, $gpio, $IN_OUT) = @_;
    # inits a single gpio pin
    _init_pins( $gpio, $pins_cfg, $IN_OUT);
    _init_pins( $gpio, $pins_state);
}

sub _init_pins {
    my ($gpio, $pins_i, $IN_OUT) = @_;

    # gpio = { # something like :
    #    i2c_bus  => 0,
    #	 i2c_addr => '0x20',
    #	 portname =>'b',
    #	 portnum  => 1,
    # };

    $pins_i->{$gpio->{i2c_bus}} = {}
        if ! exists $pins_i->{get_hashval($gpio, 'i2c_bus')};

    my $i2c_bus_rh = $pins_i->{$gpio->{i2c_bus}};

    ##
    $i2c_bus_rh->{$gpio->{i2c_addr}} = {}
        if ! exists $i2c_bus_rh->{get_hashval($gpio, 'i2c_addr')};

    my $i2c_addr_rh = $i2c_bus_rh->{$gpio->{i2c_addr}};

    # Default of 11111111 0xff , so the IODIR defaults to input.
    # this is electronically safer for the MCP23017
    $i2c_addr_rh->{lc($gpio->{portname})} = [ 1,1,1,1,1,1,1,1 ]
        if ! exists $i2c_addr_rh->{get_hashval($gpio, 'portname')};

    $gpio->{portname} = lc($gpio->{portname});

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
    # reads the INs , writes the OUTs

}




#    $IN_OUT = lc( $IN_OUT );
#    klogfatal "Can only set a Pi GPIO mode ($IN_OUT) to 'in' or 'out'"
#        if $IN_OUT ne IN and $IN_OUT ne OUT;
#
#    system("$PI_GPIO_CMD mode $gpio_num $IN_OUT");
#}

sub read_gpio {
    my ($class, $gpio_num) = @_;
    # reads a single gpio pin
#    my $r = qx( $PI_GPIO_CMD read $gpio_num );
#    chomp $r;
#    return $r;
}

sub write_gpio {
    my ($class, $gpio_num, $val) = @_;
    # writes a single gpio pin
#    system("$PI_GPIO_CMD write $gpio_num $val");
#    return;
}


#_pin_array_to_num  and  _num_to_pin_array {
# convert an array with 8 elements  [ 0..7]
# to a number and vice-versa
# where element 0 == bit 0
sub _pin_array_to_num {
    my ( $array ) = @_;
    confess "array doesn't have 8 elements" if @$array != 8;

    return oct("0b".join( "", reverse @$array));
}

sub _num_to_pin_array {
    my ( $num ) = @_;

    confess "number is not between 0 and 255"
        if $num < 0 || $num > 255;

    return [ reverse split ( //, sprintf("%08b", $num ) )];

}


1;

