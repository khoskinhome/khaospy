package Khaospy::ControlDispatch;
use strict;
use warnings;
# By Karl Kaiser-Kount-Kaptain-Khaos Hoskin. 2015-2016

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;

#use Khaospy::ControlOther;
#use Khaospy::ControlPi;

use Khaospy::Constants qw(
    true false
    ON OFF STATUS
    AUTO MANUAL
    IN $IN OUT $OUT

);

use Khaospy::Log qw(
    klogdebug
);

use Khaospy::Utils qw(
    get_hashval
);

our @EXPORT_OK = qw(
    init_dispatch
    dispatch_poll
    dispatch_operate
);

my $dispatch ;
my $unhandled_type_cb;
my $controls;

sub init_dispatch {
    my ( $p_dispatch, $p_unhandled_cb, $p_controls ) = @_;
    $dispatch           = $p_dispatch;
    $unhandled_type_cb  = $p_unhandled_cb;
    $controls           = $p_controls;
    _dispatch("init");
}

sub _dispatch {
    my ($dispatch_type, $poll_callback) = @_;

    my $t_dispatch = get_hashval($dispatch, $dispatch_type);

    for my $control_name ( keys %$controls ){

        my $control = $controls->{$control_name};
        my $type = $control->{type};

        if ( exists $t_dispatch->{$type} ){
            next if ! defined $t_dispatch->{$type};
            klogdebug "$dispatch_type control $control_name";
            $t_dispatch->{$type}->(
                $control_name,
                $control,
                $poll_callback
            );
            next;
        }
    }
}

sub dispatch_poll {
    my ($poll_callback) = @_;
    _dispatch("poll", $poll_callback );
}

sub dispatch_operate{
    my ( $control_name, $control, $action ) = @_;

    my $type = $control->{type};

    my $operate_dispatch = get_hashval($dispatch,'operate');

    return $operate_dispatch->{$type}->($control_name,$control, $action)
        if exists $operate_dispatch->{$type};

    $unhandled_type_cb->($control_name);

}

1;
