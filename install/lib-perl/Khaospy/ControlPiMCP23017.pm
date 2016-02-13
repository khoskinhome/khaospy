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

