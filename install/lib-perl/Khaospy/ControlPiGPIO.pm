package Khaospy::ControlPiGPIO;
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

# This applies to all the "relay-manual" controls where there is override.
# maybe even the orviboS20s

# Khaospy is going to need to detect that the control has been manually operated.
# This is useful for the "rules" part. i.e a rule will know the last-manual-operation time.
#
# So having a status of "last_manual_change" set to a timestamp will enable rules to be "clever".
# So therefore going to need "last_auto_change" as the counter point .
#
# A control needs its state querying before any auto operation.
# If the state has changed since the last poll, then it can be assumed this was manually carried out.
#
#
# So there will be 3 state fields :

# current_state (ON/OFF)
# current_state_change_time     ( timestamp )
# last_manual_state_change      ( ON/OFF )
# last_manual_state_change_time ( timestamp )
# last_auto_state_change        ( ON/OFF )
# last_auto_state_change_time   ( timestamp )

# The orviboS20 will be fun, because quite often they seem to be "unavailable" .


# This module is used by the Khaospy::PiControllerDaemon;
#
#use Exporter qw/import/;
#use Data::Dumper;
#use Carp qw/croak/;
#use JSON;
#
#use ZMQ::LibZMQ3;
#use ZMQ::Constants qw(
#    ZMQ_SUB
#    ZMQ_SUBSCRIBE
#    ZMQ_RCVMORE
#    ZMQ_FD
#    ZMQ_PUB
#);
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
#);
#
#use Khaospy::Utils qw(
#    slurp
#);
#
##pi@pitest ~ $ gpio mode 1 out
##pi@pitest ~ $ gpio mode 4 out
##pi@pitest ~ $ gpio write 1 0
##pi@pitest ~ $ gpio write 1 1
##pi@pitest ~ $ gpio write 4 1
##
#our @EXPORT_OK = qw( signal_control );
#
#sub signal_control {
#    my ( $control, $action ) = @_ ;
#
#    # there needs to be a listening daemon on the pi that has the gpio pins.
#    #  that will run the command to
#    # set the gpio port direction
#    # read the gpio state
#    # set the gpio state
#
#
#}


1;
