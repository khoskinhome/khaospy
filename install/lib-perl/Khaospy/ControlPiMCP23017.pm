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
    init_pi_mcp23017_controls
    poll_pi_mcp23017_controls
);


sub init_pi_mcp23017_controls {
    kloginfo  "Initialise PiMCP23017 controls";

}

sub poll_pi_mcp23017_controls {
    klogdebug "Poll PiMCP23017 controls";


}


my $mcp23017_state = {};

sub init_pi_gpio {
    my ($gpio_num, $IN_OUT) = @_;
#    $IN_OUT = lc( $IN_OUT );
#    klogfatal "Can only set a Pi GPIO mode ($IN_OUT) to 'in' or 'out'"
#        if $IN_OUT ne IN and $IN_OUT ne OUT;
#
#    system("$PI_GPIO_CMD mode $gpio_num $IN_OUT");
}

sub read_pi_gpio {
    my ($gpio_num) = @_;
#    my $r = qx( $PI_GPIO_CMD read $gpio_num );
#    chomp $r;
#    return $r;
}

sub write_pi_gpio {
    my ($gpio_num, $val) = @_;
#    system("$PI_GPIO_CMD write $gpio_num $val");
#    return;
}


sub read_mcp23017 {
    # reads from the MCP23017
}

sub write_mcp23017 {

}

sub init_mcp23017 {}

#
#
#my $json = JSON->new->allow_nonref;
#
#use FindBin;
#FindBin::again();
#use lib "$FindBin::Bin/../lib-perl";
#
#use Khaospy::Constants qw(
#    true false
#    ON OFF STATUS
#    $KHAOSPY_CONTROLS_CONF_FULLPATH
#    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF
#);
#
#use Khaospy::Utils qw(
#    slurp
#);
#
#our @EXPORT_OK = qw( signal_control );
#
#sub signal_control {
#
#    # there needs to be a listening daemon on the pi that has the gpio pins.
#    #  that will run the command to
#    # set the gpio port direction
#    # read the gpio state
#    # set the gpio state
#
#
#}
#

1;

