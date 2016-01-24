package Khaospy::ControlPiGPIO;
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

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
