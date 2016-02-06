package Khaospy::ControlPiGPIO;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Khaospy::Constants qw(
    $PI_GPIO_CMD
    true false
    ON OFF STATUS
);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

our @EXPORT_OK = qw(
    init_pi_gpio_controls
    operate_pi_gpio_relay
);

sub init_pi_gpio_controls {
    kloginfo  "Initialise PiGPIO controls";

    # TODO this needs to go through the config for the host it is running on
    # and set the GPIO direction of all the configured ports.

}

sub operate_pi_gpio_relay {
    my ($control_name,$control, $action) = @_;

    kloginfo "OPERATE $control_name with $action";

    my $gpio_num = $control->{gpio_relay};

    # Initialising port IN or OUT
    # should be done when PiControllerDaemon first starts :
    init_pi_gpio($gpio_num, "out");

    write_pi_gpio($gpio_num, trans_ON_to_true(invert_state($control,$action)))
        if $action ne STATUS;

    return trans_true_to_ON(
        invert_state($control,read_pi_gpio($gpio_num))
    );
}

# For the initialisation, reading and writing of Pi GPIO pins.
# I should possibly use https://github.com/WiringPi/WiringPi-Perl
# but that needs compiling etc. No CPAN module. hmmm.
# From the CLI this init, read and write are done like so :
#  /usr/bin/gpio mode  4 out
#  /usr/bin/gpio write 4 0
#  /usr/bin/gpio write 4 1
#  /usr/bin/gpio read  4

sub init_pi_gpio {
    my ($gpio_num, $IN_OUT) = @_;
    $IN_OUT = lc( $IN_OUT );
    fatal_invalid_pi_gpio($gpio_num);
    klogfatal "Can only set a Pi GPIO mode ($IN_OUT) to 'in' or 'out'"
        if $IN_OUT ne "in" and $IN_OUT ne "out";

    system("$PI_GPIO_CMD mode $gpio_num $IN_OUT");
}

sub read_pi_gpio {
    my ($gpio_num) = @_;
    fatal_invalid_pi_gpio($gpio_num);
    my $r = qx( $PI_GPIO_CMD read $gpio_num );
    chomp $r;
    return $r;
}

sub write_pi_gpio {
    my ($gpio_num, $val) = @_;
    fatal_invalid_pi_gpio($gpio_num);
    system("$PI_GPIO_CMD write $gpio_num $val");
    return;
}

sub fatal_invalid_pi_gpio {
    my ($gpio_num) = @_;
    klogfatal "gpio number can only be 0 to 7" if $gpio_num !~ /^[0-7]$/;
}

# these helper subs need to be in a Khaospy::OperateControls module,
# that is when the current Khaospy::OperateControls.pm is renamed to Khaospy::OperateControl.pm

# Stating possibly the "bleedin' obvious,
# ON eq "on" , and OFF eq "off"
# true == 1 , false == 0
# These subs translate both ways from ON to true and OFF to false.

sub trans_true_to_ON { # and false to OFF
    my ($truefalse) = @_;
    return ON  if $truefalse == true;
    return OFF if $truefalse == false;
    klogfatal "Can't translate a non true or false value ($truefalse) to ON or OFF";
}

sub trans_ON_to_true { # and OFF to false
    my ($ONOFF) = @_;
    return true  if $ONOFF eq ON;
    return false if $ONOFF eq OFF;
    klogfatal "Can't translate a non ON or OFF value ($ONOFF) to true or false";
}
sub invert_state {
    # if a control has "invert_state" option set then this
    # inverts both ON/OFF and true/false
    my ( $control, $val ) = @_;

    return $val
        if ! exists $control->{invert_state}
            || $control->{invert_state} eq false ;

    if ( $val eq ON || $val eq OFF ){

        return ($val eq ON) ? OFF : ON ;

    } elsif ($val eq true or $val eq false) {

        return ( $val ) ? false : true ;

    }

    klogfatal "Unrecognised value ($val) passed to invert_state()";
}

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
