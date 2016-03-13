package Khaospy::ControlPiBoilerHomeEasy;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

# This is a very hacky hardcoded controller for my one-off of
# getting an homeeasy remote control by pi-gpios.
#
# it doesn't seem worth the effort going through all the config stuff.
# there is an hardcoded config. this is never going to be used more than once.
# homeeasy controls are crap, and will be deprecated from my system.

use Try::Tiny;
use Carp qw/confess croak/;
use Data::Dumper;
use Exporter qw/import/;
use Time::HiRes qw/usleep time/;

use Khaospy::Constants qw(
    IN $IN OUT $OUT
    ON OFF
);

use Khaospy::ControlPiGPIO;
our @EXPORT_OK = qw(
    operate
    run_rules_daemon
);

# config for the gpio pins :
my $remote_channel = {

    1 => { ON() => 22, OFF() => 23 },
    2 => { ON() => 24, OFF() => 25 },
    3 => { ON() => 26, OFF() => 27 },
    4 => { ON() => 28, OFF() => 29 },
};

my $rules = [
    {
        start_time  => '0000',
        end_time    => '0600',
        day_of_week => qr/^[12345]$/,
        action      => OFF,
        channel     => 1,
    },

    {
        start_time  => '0100',
        end_time    => '0600',
        day_of_week => qr/^[67]$/,
        action      => OFF,
        channel     => 1,
    },

    {
        start_time  => '2200',
        end_time    => '2359',
        day_of_week => qr/^[71234]$/,
        action      => OFF,
        channel     => 1,
    },
];


sub init {
    for my $chan ( keys %$remote_channel ) {
        my $chan_cfg =  $remote_channel->{$chan};
        Khaospy::ControlPiGPIO->init_gpio($chan_cfg->{ON()}, OUT);
        Khaospy::ControlPiGPIO->init_gpio($chan_cfg->{OFF()}, OUT);
    }
}

sub set_all_off {
    for my $chan ( keys %$remote_channel ) {
        my $chan_cfg =  $remote_channel->{$chan};
        Khaospy::ControlPiGPIO->write_gpio($chan_cfg->{ON()}, OFF);
        Khaospy::ControlPiGPIO->write_gpio($chan_cfg->{OFF()}, OFF);
    }
}

sub operate {
    my ( $channel, $action ) = @_;
    init();
    set_all_off();

    die "Invalid action '$action'\n" if $action ne ON and $action ne OFF;

    die "Invalid channel '$channel'\n"
        if not exists $remote_channel->{$channel};

    Khaospy::ControlPiGPIO->write_gpio(
        $remote_channel->{$channel}{$action},
        ON()
    );

    sleep 1;

    set_all_off();
}

sub run_rules_daemon {
    while ( 1 ) {
        sleep 20;
        _run_rules( DateTime->now(), $rules );
    }
}

sub _run_rules {
    my ($dt,$rules) = @_;
    for my $rule ( @$rules ) {
        next if $dt->day_of_week !~ $rule->{day_of_week};

        my $timenow = sprintf("%02d%02d", $dt->hour, $dt->minute);

        if ( $timenow ge $rule->{start_time} and $timenow le $rule->{end_time} ){

            operate( $rule->{channel}, $rule->{action} );
            usleep 200000;
        }
    }
}

1;
