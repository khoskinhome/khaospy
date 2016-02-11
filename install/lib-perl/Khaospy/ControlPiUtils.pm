package Khaospy::ControlPiUtils;
use strict;
use warnings;
# By Karl Kount-Khaos Hoskin. 2015-2016

# few common subs for Controls on a Pi.

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Khaospy::Constants qw(
    ON OFF
    true false

);

use Khaospy::Log qw(
    klogstart klogfatal klogerror
    klogwarn  kloginfo  klogdebug
);

our @EXPORT_OK = qw(
    trans_true_to_ON
    trans_ON_to_true
    invert_state
);

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

1;
