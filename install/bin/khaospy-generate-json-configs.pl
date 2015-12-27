#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use JSON;

# generate the daemon-runner JSON conf file in perl !

my $khaospy_conf_root = "/opt/khaospy/conf";
my $json = JSON->new->allow_nonref;

my %conffiles = (
    'daemon-runner.json'
        => daemon_runner_conf(),
    'heating_thermometer.json'
        => heating_thermometer_config(),
);

for my $conf_file ( keys %conffiles ) {

    burp ( "$khaospy_conf_root/$conf_file",
            $json->pretty->encode( $conffiles{$conf_file} )
    );
}

sub burp {
    my( $file_name ) = shift ;
    open( my $fh, ">" , $file_name ) || die "can't create $file_name $!" ;
    print $fh @_ ;
}


sub daemon_runner_conf {
    return {
        piserver => [
            "/opt/khaospy/bin/khaospy-one-wired-receiver.py --host=pioldwifi",
            "/opt/khaospy/bin/khaospy-one-wired-receiver.py --host=piloft",
    #        "/opt/khaospy/bin/khaospy-orvibo-s20-radiator.pl",
        ],
    #    piserver2 => [
    #    ],
        piloft => [
            "/opt/khaospy/bin/khaospy-one-wired-sender.py --stdout_freq=890",
            "/opt/khaospy/bin/khaospy-amelia-hackit-daemon.pl",
        ],
        piold => [
            "/opt/khaospy/bin/khaospy-one-wired-sender.py --stdout_freq=890",
        ],
    };
}

# Heating conf keys :
#     name             => 'Alison',
#     rrd_group        => 'upstairs',
#     upper_temp       => 22, # when temp is higher than this the "off" command will be sent.
#     lower_temp       => 20, # when temp is less than this, the "on" command will be sent.
#     closed_switches  => Array of swtiches that must be closed for "on" command.
#                               if any of the switches are open an "off" command will be sent.
#     turn_on_command  => command to switch on heating,
#     turn_off_command => command to switch off heating',

sub heating_thermometer_config {
    return {
        '28-0000066ebc74' => {
            name             => 'Alison',
            rrd_group        => 'upstairs',
            upper_temp       => 22,
            lower_temp       => 20,
            closed_switches  => [],
            turn_on_command  => 'orviboS20 alisonrad on',
            turn_off_command => 'orviboS20 alisonrad off',
        },
        '28-000006e04e8b' => {
            name             => 'Playhouse-tv',
            rrd_group        => 'outside',
            upper_temp       => 22,
            lower_temp       => 20,
            closed_switches  => [],
            turn_on_command  => '',
            turn_off_command => '',
        },
        '28-0000066fe99e' => {
            name             => 'Playhouse-9e-door',
            rrd_group        => 'outside',
            upper_temp       => 22,
            lower_temp       => 20,
            closed_switches  => [],
            turn_on_command  => '',
            turn_off_command => '',
        },
        '28-00000670596d' => {
            name             => 'Bathroom',
            rrd_group        => 'upstairs',
            upper_temp       => 22,
            lower_temp       => 20,
            closed_switches  => [],
            turn_on_command  => '',
            turn_off_command => '',
        },
        '28-021463277cff' => {
            name             => 'Loft',
            rrd_group        => 'upstairs',
            upper_temp       => 22,
            lower_temp       => 20,
            closed_switches  => [],
            turn_on_command  => '',
            turn_off_command => '',
        },
        '28-0214632d16ff' => {
            name             => 'Amelia',
            rrd_group        => 'upstairs',
            upper_temp       => 22,
            lower_temp       => 20,
            closed_switches  => [],
            turn_on_command  => 'orviboS20 ameliarad on',
            turn_off_command => 'orviboS20 ameliarad off',
        },
        '28-021463423bff' => {
            name             => 'Upstairs-Landing',
            rrd_group        => 'upstairs',
            upper_temp       => 22,
            lower_temp       => 20,
            closed_switches  => [],
            turn_on_command  => '',
            turn_off_command => '',
        },
    };
}




