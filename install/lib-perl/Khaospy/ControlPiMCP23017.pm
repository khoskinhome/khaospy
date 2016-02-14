package Khaospy::ControlPiMCP23017;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

# This module is used by the Khaospy::PiControllerDaemon;
use Try::Tiny;
use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

our @EXPORT_OK = qw(
    init_gpio
    read_gpio
    write_gpio
);

#sub init_pi_mcp23017_controls {
#    kloginfo  "Initialise PiMCP23017 controls";
#
#}
#
#sub poll_pi_mcp23017_controls {
#    klogdebug "Poll PiMCP23017 controls";
#
#
#}

my $mcp23017_pins_state = {};

sub init_gpio {
    my ($class, $gpio_num, $IN_OUT) = @_;
#    $IN_OUT = lc( $IN_OUT );
#    klogfatal "Can only set a Pi GPIO mode ($IN_OUT) to 'in' or 'out'"
#        if $IN_OUT ne IN and $IN_OUT ne OUT;
#
#    system("$PI_GPIO_CMD mode $gpio_num $IN_OUT");
}

sub read_gpio {
    my ($class, $gpio_num) = @_;
#    my $r = qx( $PI_GPIO_CMD read $gpio_num );
#    chomp $r;
#    return $r;
}

sub write_gpio {
    my ($class, $gpio_num, $val) = @_;
#    system("$PI_GPIO_CMD write $gpio_num $val");
#    return;
}

1;

