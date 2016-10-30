package Khaospy::ControlPiMCP23017;
use strict;
use warnings;
# by Karl Khaos Hoskin. 2015-2016

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

    $PI_CONTROL_MCP23017_PINS_TIMEOUT
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

use Khaospy::Utils qw(
    get_hashval
    get_cmd
);

our @EXPORT_OK = qw(
    init_mcp23017
    init_gpio
    read_gpio
    write_gpio
);

# datastructures used is this module :

# $pins_[cfg|in_state|out_state] = {
#    <i2c_bus> => {                 # key is 0 or 1 , maybe even 2
#        <i2c_addr> => {            # key is "0x20" -> "0x27" (string)
#            <port_a|port_b> => [   # key is "a" or "b"
#                bit0,
#                bit1,
#                ....
#                bit7
#            ]
#            <port_a_last_update|port_b_last_update> => time # key is "a_last_update" or "b_last_update"
#        }
#    },
#
# }
#
# This datastructure comes from the controls config :
# gpio = { # something like :
#       i2c_bus  => 0,
#	i2c_addr => '0x20',
#	portname =>'b',
#	portnum  => 1,
# };


# IODIR, GPIO and OLAT are terms used on the Microchip's MCP23017 data-sheet

# IODIR A/B are used to set the direction of the gpio pin
# 0 for output, 1 for input. ( i.e. 0xFF is all input )
my $IODIR = { a => '0x00', b => '0x01' };

# GPIO A/B are used to get the input on a mcp23017 port
my $MCP_GPIO  = { a => '0x12', b => '0x13' };

# OLAT A/B are used to switch on and off the outputs on a mcp23017 port.
my $OLAT  = { a => '0x14', b => '0x15' };

my $pins_cfg = {}; # used by IODIR[A|B]
my $pins_out = {}; # used by OLAT[A|B]
my $pins_in  = {}; # used by GPIO[A|B]

# needed for unit testing :
sub testing_get_pins_cfg       { $pins_cfg }
sub testing_set_pins_cfg       { $pins_cfg = $_[0] }
sub testing_get_pins_in_state  { $pins_in }
sub testing_set_pins_in_state  { $pins_in = $_[0] }
sub testing_get_pins_out_state { $pins_out }
sub testing_set_pins_out_state { $pins_out = $_[0] }

sub init_gpio {
    my ($class, $gpio, $IN_OUT ) = @_;
    # inits a single gpio pin
    _init_pins( $gpio, $pins_cfg, $IN_OUT, true  );
    _init_pins( $gpio, $pins_in , undef  , true  ) if $IN_OUT eq IN;
    _init_pins( $gpio, $pins_out, undef  , false ) if $IN_OUT eq OUT;

    # TODO. Could I do this better ?
    # A bit of a hack , since this will affect a higher level datastructure.
    # ( breaking encapsulation )
    # This is done so that the correct $pins_in or $pins_out
    # array can be selected in read_gpio()
    $gpio->{iodir} = $IN_OUT;
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
    # Default of 0b11111111 / 0xff, so the IODIR defaults to input.
    # This is electronically safer for the MCP23017
    $i2c_addr_rh->{lc($gpio->{portname})} = [ map { $default_bit } 0..7 ]
        if ! exists $i2c_addr_rh->{$gpio->{portname}};

    return if ! defined $IN_OUT;

    klogfatal "Can only set a Pi MCP23017 mode ($IN_OUT) to 'in' or 'out'"
        if $IN_OUT ne IN and $IN_OUT ne OUT;

    $i2c_addr_rh->{$gpio->{portname}}[ get_hashval($gpio,'portnum')]
        = ( $IN_OUT eq IN ) ? true : false ;
}

sub init_mcp23017 {
    # needs to be called once all the pins are init-ed by init_gpio()
    for my $i2c_bus ( keys %$pins_cfg ){
        my $bus_rh = get_hashval($pins_cfg,$i2c_bus);
        for my $i2c_addr ( keys %$bus_rh ){
            my $addr_rh = get_hashval($bus_rh, $i2c_addr);
            for my $port ( qw/a b/ ){
                next if ! exists $addr_rh->{$port};

                my $cmd = sprintf("%s -y %s %s %s 0x%02x",
                    $PI_I2C_SET,
                    $i2c_bus,
                    $i2c_addr,
                    $IODIR->{$port},
                    _pin_array_to_num($addr_rh->{$port})
                );

                try {
                    my $ret = _get_mcp23017_cmd( $cmd );
                    kloginfo "init_mcp23017(). Shell command '$cmd' returned '$ret'";
                } catch {
                    klogerror
                        sprintf ("i2c_bus = %s : i2c_addr = %s : port = %s \n%s" ,
                            $i2c_bus,
                            $i2c_addr,
                            $port,
                            ref ( $_ ) ,
                        );
                    klogdebug $_;
                }

            }
        }
    }
}

sub get_pins_i_name {
    my ( $pins_i ) = @_;
    return 'pins_cfg'       if $pins_i == $pins_cfg;
    return 'pins_in_state'  if $pins_i == $pins_in;
    return 'pins_out_state' if $pins_i == $pins_out;
    return 'unknown-pins-datastructure';
}

sub get_pins_array {
    my ($gpio, $pins_i) = @_;

    my $i2c_addr_rh = _get_pins_array_to_i2c_addr($gpio, $pins_i);

    $gpio->{portname} = lc(get_hashval($gpio, 'portname'));
    klogfatal get_pins_i_name($pins_i)." doesn't have portname set"
        if ! exists $i2c_addr_rh->{$gpio->{portname}};
    my $array_ra = $i2c_addr_rh->{$gpio->{portname}};

    return $array_ra;
}

sub set_last_update {
    my ($gpio, $pins_i ) = @_;

    my $i2c_addr_rh = _get_pins_array_to_i2c_addr($gpio, $pins_i);
    $gpio->{portname} = lc(get_hashval($gpio, 'portname'));

    my $last_key = $gpio->{portname}."_last_update";

    $i2c_addr_rh->{$last_key} = time
}

sub last_update {
    my ($gpio, $pins_i ) = @_;

    my $i2c_addr_rh = _get_pins_array_to_i2c_addr($gpio, $pins_i);
    $gpio->{portname} = lc(get_hashval($gpio, 'portname'));

    my $last_key = $gpio->{portname}."_last_update";

    $i2c_addr_rh->{$last_key} = 0
        if ! exists $i2c_addr_rh->{$last_key};

    return $i2c_addr_rh->{$last_key} ;
}

sub _get_pins_array_to_i2c_addr {
    my ($gpio, $pins_i) = @_;

    klogfatal get_pins_i_name($pins_i)." doesn't have i2c_bus set", $pins_i
        if ! exists $pins_i->{get_hashval($gpio, 'i2c_bus')};
    my $i2c_bus_rh = $pins_i->{$gpio->{i2c_bus}};

    klogfatal get_pins_i_name($pins_i)." doesn't have i2c_addr set", $pins_i
        if ! exists $i2c_bus_rh->{get_hashval($gpio, 'i2c_addr')};

    return $i2c_bus_rh->{$gpio->{i2c_addr}};
}

sub set_pins_state_array {
    my ( $gpio, $pins_i, $new_state ) = @_;

    klogfatal "new_state ($new_state) isn't 1 or 0 or an array"
        if $new_state != true and $new_state != false and ref $new_state ne "ARRAY";

    # Should never need to set the pins_cfg after init.
    klogfatal get_pins_i_name($pins_i)." is not settable"
        if $pins_i != $pins_in
            and $pins_i != $pins_out;

    if ( ref $new_state ne "ARRAY" ) {
        get_pins_array($gpio, $pins_i)->[ get_hashval($gpio,'portnum') ]
            = $new_state;
    } else {
        @{get_pins_array($gpio, $pins_i)} = @$new_state ;
    }
}

sub read_gpio {
    my ( $class, $gpio ) = @_;

    my ( $MCP_register, $pins_i );

    if ( get_hashval($gpio, 'iodir') eq OUT ){
        $pins_i       = $pins_out;
        $MCP_register = $OLAT;
    } else { # must be "IN"
        $pins_i       = $pins_in;
        $MCP_register = $MCP_GPIO;
    };

    my $last_update = last_update($gpio, $pins_i);
    if ( $last_update + $PI_CONTROL_MCP23017_PINS_TIMEOUT < time ){
        my $cmd = sprintf("%s -y %s %s %s",
            $PI_I2C_GET,
            $gpio->{i2c_bus},
            $gpio->{i2c_addr},
            $MCP_register->{$gpio->{portname}},
        );

        my $ret = _get_mcp23017_cmd( $cmd );
        klogdebug "Shell command '$cmd' returned '$ret'";
        set_pins_state_array(
            $gpio,
            $pins_i,
            _num_to_pin_array( hex( $ret ) ),
        );

        set_last_update($gpio, $pins_i)
    }

    return get_pins_array( $gpio, $pins_i )
        ->[ get_hashval($gpio, 'portnum') ];
}

sub write_gpio {
    my ( $class, $gpio, $new_state ) = @_;

    if ( get_hashval($gpio, 'iodir') eq IN ){
        klogfatal "trying to write to a gpio pin that has been configured as input";
    };

    set_pins_state_array($gpio, $pins_out, $new_state);

    my $cmd = sprintf("%s -y %s %s %s 0x%02x",
        $PI_I2C_SET,
        $gpio->{i2c_bus},
        $gpio->{i2c_addr},
        $OLAT->{$gpio->{portname}},
        _pin_array_to_num(
            get_pins_array($gpio, $pins_out)
        )
    );
    my $ret = _get_mcp23017_cmd( $cmd );
    klogdebug "Shell command '$cmd' returned '$ret'";
}

sub _pin_array_to_num {
    my ( $array ) = @_;

    klogfatal "Array either doesn't have 8 bits for gpio or a bit is not either 1 or 0",
        $array if @$array != 8 || grep { $_ != true and $_ != false } @$array;

    return oct("0b".join( "", reverse @$array));
}

sub _num_to_pin_array {
    my ( $num ) = @_;
    # returns an array-ref where element 0 == bit-0
    klogfatal "number is not between 0 and 255"
        if $num < 0 || $num > 255;

    return [ reverse split ( //, sprintf("%08b", $num ) )];

}

sub _get_mcp23017_cmd {
    return get_cmd(@_);
}


1;

