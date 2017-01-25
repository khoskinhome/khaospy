package Khaospy::ControlsCurrentState;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2017

# WORK IN PROGRESS

#TODO make this an object ? Maybe Moo or Mouse.
# but how many cpan packages would that add to the dependency list ?
# something to think about ...

our @EXPORT_OK = qw(


);

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

use Scalar::Util qw(looks_like_number);

use Khaospy::Conf::Controls qw(
    get_control_config
    get_controls_conf
);

use Khaospy::DBH::Controls qw(
    get_controls
);

use Khaospy::Constants qw(
    $JSON

    true  $true  ON  $ON
    false $false OFF $OFF

    STATUS $STATUS
);

use Sys::Hostname;

use List::Compare;

my $controls_state = {};

my $set_updates_db = false;

# ctl = control !

# Setters will :
    # return true  if the value changed
    # return false if the value didn't change.

# Getters will return the value of the field.

# most methods are combined get/set.
# i.e. with one param it gets the control field
# with 2 params it sets the control field.

sub init_from_db (){
    # TODO
    die("TODO-not-yet-implemented");
}

sub set_to_update_db (){
    $set_updates_db = true;
}

sub unset_to_update_db (){
    $set_updates_db = false;
}

#############################
# update a control from message

sub set_ctl_from_message ($$) {
    my ($control_name, $msg) = @_;
    die("TODO-not-yet-implemented");

}

#############################
# individual field getter setters :

sub ctl_type ($;$){
    my ( $control_name, $set ) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_alias ($;$){
    my ( $control_name, $set ) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_value ($;$){
    my ($control_name, $set) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_value_bool ($){ # can't set
    my ($control_name) = @_;
    die("TODO-not-yet-implemented");
    # TODO
    # returns 1 or 0

}

sub ctl_config_json ($;$){
    my ( $control_name, $set ) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_manual_auto_timeout_left ($){
    # not sure about a setter method for this
    # manual-auto-timeout is part of the config on manually operatable controls.
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_last_change_state_by ($;$){
    my ( $control_name, $set ) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_last_change_state_time_epoch ($;$){
    my ( $control_name, $set ) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_last_change_state_timestamp ($;$){
    my ( $control_name, $set ) = @_;
    die("TODO-not-yet-implemented");
    # will need to obey the global config's TZ setting ( not in there yet )
    # TODO

}

sub ctl_request_time_epoch ($;$){
    my ( $control_name, $set ) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_request_timestamp ($;$){
    my ( $control_name, $set ) = @_;
    die("TODO-not-yet-implemented");
    # will need to obey the global config's TZ setting ( not in there yet )
    # TODO

}

sub ctl_db_update_time_epoch ($){ # can't set this ! that's for the DB to do.
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
    # TODO

}

sub ctl_db_update_timestamp ($){ # can't set this ! that's for the DB to do.
    # will need to obey the global config's TZ setting ( not in there yet )
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");

}

####################
# is / comparision methods.

# boolean control type comparators :
sub is_ctl_on ($){ # what should this do for non-binary controls ?
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
}

sub is_ctl_off ($){ # what should this do for non-binary controls ?
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
}

# dimmable and multi-light comparators :
# what should they do for binary controls ?
sub is_ctl_half_on ($) { # == 0.5
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
}

sub is_ctl_more_on ($) { # > 0.5
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
}

sub is_ctl_half_or_more_on ($) { # >= 0.5
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
}

sub is_ctl_more_off ($) { # < 0.5
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
}

sub is_ctl_half_or_more_off ($) { # < 0.5
    my ( $control_name ) = @_;
    die("TODO-not-yet-implemented");
}


1;
