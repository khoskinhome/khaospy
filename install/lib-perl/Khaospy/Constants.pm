package Khaospy::Constants;
use strict;
use warnings;

# install/bin/testrig-lighting-on-off-2relay-automated-with-detect.pl:sub burp {

use Exporter qw/import/;

sub true  { 1 };
sub false { 0 };

sub ON      { "on"  };
our $ON     = ON();

sub OFF     { "off" };
our $OFF    = OFF();

sub STATUS  { "status" };
our $STATUS = STATUS();

#######
# dirs

our $KHAOSPY_ALL_DIRS = [
    our $KHAOSPY_ROOT_DIR      = "/opt/khaospy",
    our $KHAOSPY_BIN_DIR       = "$KHAOSPY_ROOT_DIR/bin",
    our $KHAOSPY_CONF_DIR      = "$KHAOSPY_ROOT_DIR/conf",
    our $KHAOSPY_LOG_DIR       = "$KHAOSPY_ROOT_DIR/log",
    our $KHAOSPY_PID_DIR       = "$KHAOSPY_ROOT_DIR/pid",
    our $KHAOSPY_RRD_DIR       = "$KHAOSPY_ROOT_DIR/rrd",
    our $KHAOSPY_RRD_IMAGE_DIR = "$KHAOSPY_ROOT_DIR/rrdimage",
    our $KHAOSPY_WWW_DIR       = "$KHAOSPY_ROOT_DIR/www",
    our $KHAOSPY_WWW_BIN_DIR   = "$KHAOSPY_ROOT_DIR/www-bin",
];

#################
# daemon scripts

our $KHAOSPY_ONE_WIRED_SENDER_SCRIPT
    = "$KHAOSPY_BIN_DIR/khaospy-one-wired-sender.py";

our $KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT
    = "$KHAOSPY_BIN_DIR/khaospy-one-wired-receiver.py";

our $KHAOSPY_ONE_WIRE_HEATING_DAEMON
    = "$KHAOSPY_BIN_DIR/khaospy-one-wire-heating-daemon.pl";

our $KHAOSPY_BOILER_DAEMON_SCRIPT
    = "$KHAOSPY_BIN_DIR/khaospy-boiler-daemon.pl";

#############
# json confs
our $KHAOSPY_ALL_CONFS = {
    our $KHAOSPY_DAEMON_RUNNER_CONF
        = "daemon-runner.json"          => daemon_runner_conf(),
    our $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF
        = "heating_thermometer.json"    => heating_thermometer_config(),
    our $KHAOSPY_CONTROLS_CONF
        = "controls.json"               => controls_conf(),
    our $KHAOSPY_BOILERS_CONF
        = "boilers.json"                => boilers_conf(),
};

our $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_DAEMON_RUNNER_CONF";

our $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF";

our $KHAOSPY_CONTROLS_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_CONTROLS_CONF";

our $KHAOSPY_BOILERS_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_BOILERS_CONF";

#############

our $ONE_WIRE_DAEMON_PORT                = 5001;
our $ALARM_SWITCH_DAEMON_PORT            = 5051;
our $HEATING_CONTROL_DAEMON_PUBLISH_PORT = 5021;

######################
our @EXPORT_OK = qw(
    true false

     ON  OFF  STATUS
    $ON $OFF $STATUS

    $KHAOSPY_ALL_DIRS
    $KHAOSPY_ROOT_DIR
    $KHAOSPY_BIN_DIR
    $KHAOSPY_CONF_DIR
    $KHAOSPY_LOG_DIR
    $KHAOSPY_PID_DIR
    $KHAOSPY_RRD_DIR
    $KHAOSPY_RRD_IMAGE_DIR
    $KHAOSPY_WWW_DIR
    $KHAOSPY_WWW_BIN_DIR

    $KHAOSPY_ALL_CONFS

    $KHAOSPY_DAEMON_RUNNER_CONF
    $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH

    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH

    $KHAOSPY_CONTROLS_CONF
    $KHAOSPY_CONTROLS_CONF_FULLPATH

    $KHAOSPY_BOILERS_CONF
    $KHAOSPY_BOILERS_CONF_FULLPATH

    $KHAOSPY_ONE_WIRED_SENDER_SCRIPT
    $KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON
    $KHAOSPY_BOILER_DAEMON_SCRIPT

    $ONE_WIRE_DAEMON_PORT
    $ALARM_SWITCH_DAEMON_PORT
    $HEATING_CONTROL_DAEMON_PUBLISH_PORT

);

###############################################################################
# "conf" subs

###############################
# daemon_runner_conf keys
#
# The primary key is the hostname on where the script should run.
#
# this points to an array of script names to be run by /usr/bin/daemon ( with CLI params )
#

sub daemon_runner_conf {
    return {
        piserver => [
            "$KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT --host=pioldwifi",
            "$KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT --host=piloft",
            "$KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT --host=piboiler",
            "$KHAOSPY_ONE_WIRE_HEATING_DAEMON",
            "$KHAOSPY_BOILER_DAEMON_SCRIPT",
        ],
        piloft => [
            "$KHAOSPY_ONE_WIRED_SENDER_SCRIPT --stdout_freq=890",
            "/opt/khaospy/bin/khaospy-amelia-hackit-daemon.pl",
        ],
        piold => [
            "$KHAOSPY_ONE_WIRED_SENDER_SCRIPT --stdout_freq=890",
        ],
        piboiler => [
            "$KHAOSPY_ONE_WIRED_SENDER_SCRIPT --stdout_freq=890",
        ],

    };
}

##################################
#   Heating conf keys :
#       COMPULSORY-KEYS :
#           name               => 'Alison', COMPULSORY-KEY
#           rrd_group          => 'upstairs',
#
#       OPTIONAL-KEYS that must all be supplied together :
#           upper_temp         => 22, # when temp is higher than this the "off" command will be sent.
#           control            => control_name that to switches on heating,
#
#       OPTIONAL-KEYS that can be supplied with the turn-off-off ones above :
#           lower_temp         => 20, # when temp is less than this, the "on" command will be sent.
#                                 if lower_temp isn't supplied it defaults to ( upper_temp -1 )
#           alarm_switches     => Array of swtiches that must be closed for "on" command.
#                                 These switches will be from an "alarm_switches_conf" (yet to be written)
#                                 If any of the switches are open an "off" command will be sent.
#
# The "name" and "one-wire-address" need to swap places. This config needs to be able to cope with more than just one-wire-attached thermometers. TODO at a very much later stage.
# Doing this would mean the rrd-graph-creator and the heating-control scripts would need to be changed.
sub heating_thermometer_config {
    return {
        '28-0000066ebc74' => {
            name               => 'Alison',
            rrd_group          => 'upstairs',
            upper_temp         => 19.0,
            lower_temp         => 18.5,
            alarm_switches     => [],
            control            => 'alisonrad',
        },
        '28-000006e04e8b' => {
            name               => 'Playhouse-tv',
            rrd_group          => 'sheds',
#            upper_temp         => 21,
        },
        '28-0000066fe99e' => {
            name               => 'Playhouse-9e-door',
            rrd_group          => 'sheds',
        },
        '28-00000670596d' => {
            name               => 'Bathroom',
            rrd_group          => 'upstairs',
        },
        '28-021463277cff' => {
            name               => 'Loft',
            rrd_group          => 'upstairs',
        },
        '28-0214632d16ff' => {
            name               => 'Amelia',
            rrd_group          => 'upstairs',
            upper_temp         => 19.0,
            lower_temp         => 18.5,
            alarm_switches     => [],
            control            => 'ameliarad',
        },
        '28-021463423bff' => {
            name               => 'Upstairs-Landing',
            rrd_group          => 'upstairs',
        },
        '28-000006e04d3c' => {
            name               => 'Outside-front-drive',
            rrd_group          => 'outside',
        },
        '28-000006e00a67' => {
            name               => 'boiler-ch-in-cold',
            rrd_group          => 'boiler',
        },
        '28-0114632f89ff' => {
            name               => 'boiler-ch-out-hot',
            rrd_group          => 'boiler',
        },
        '28-0414688dbfff' => {
            name               => 'boiler-wh-in-cold',
            rrd_group          => 'boiler',
        },
        '28-011465cb13ff' => {
            name               => 'boiler-wh-out-hot',
            rrd_group          => 'boiler',
        },
        '28-031463502eff' => {
            name               => 'boiler-room',
            rrd_group          => 'boiler',
        },
        '28-0214630558ff' => {
            name               => 'front-room',
            rrd_group          => 'downstairs',
            upper_temp         => 19.0,
            lower_temp         => 18.5,
            control            => 'frontroomrad',
        },
        '28-000006cafb0d' => {
            name               => 'front-porch',
            rrd_group          => 'downstairs',
        },
        '28-0000066ff2ac' => {
            name               => 'dinning-room',
            rrd_group          => 'downstairs',
            upper_temp         => 19.0,
            lower_temp         => 18.5,
            control            => 'dinningroomrad',
        },

    };
}

#################################
# controls_conf
#####
# Every control has a unique control-name.
# Controls can be switched "on" and "off" or have their "status" queried.
#
#   <type>  can be :
#               orviboS20 ( orvibos20 will also work )
#               picontroller
#   <host>  is either an hostname or ip-address
#
#   <mac>   is currently only need for Orvibo S20 controls.
#           This might be fixed in the Khaospy::OrviboS20 module, so it just needs the hostname.
#           Configuring orviboS20s is a whole "how-to" in itself, since they will only DHCP,
#           and to get static ips, and hostname via say /etc/hosts takes a bit of configuring of
#           the DHCP server, using nmap to find the orviboS20s etc..
#           The long term plan is to try and drop <mac> for Orvibo S20s.

sub controls_conf {
    ## TODO find a way of using the host name from /etc/hosts to get the ip and mac.
    return {
        alisonrad       => {
            type => "orviboS20",
            host => 'alisonrad',
            mac  => 'AC:CF:23:72:D1:FE',
        },
        ameliarad       => {
            type => "orviboS20",
            host => 'ameliarad',
            mac  => 'AC-CF-23-72-F3-D4',
        },
        karlrad         => {
            type => "orviboS20",
            host => 'karlrad',
            mac  => 'AC-CF-23-8D-7E-D2',
        },
        dinningroomrad  => {
            type => "orviboS20",
            host => 'dinningroomrad',
            mac  => 'AC-CF-23-8D-A4-8E',
        },
        frontroomrad    => {
            type => "orviboS20",
            host => 'frontroomrad',
            mac  => 'AC-CF-23-8D-3B-96',
        },
#        boiler => {
#            type => "orviboS20",
#            host => 'theboilerhostname', # FIX THIS.
#            mac  => '',
#        },
        alight => {
            type => "picontroller",
            host => "piboiler",
        },
    };
}

########################
# boilers conf.

# The primary key is the name of the control that switches a central heating boiler on.
#
# The key on_delay_secs is how long the boiler should wait before switching from "off" to "on".
# This is so the radiator-actuator-valves have been given enough time to open.
#
# The controls key is an array of radiator-actuator-controls that when they are on need the boiler to switch on.

sub boilers_conf {
    return {
        # frontroomrad is being using as the boiler control. This needs fixing.
        karlrad => {
            on_delay_secs => 120, # TODO this should really be 120
            controls => [qw/
                alisonrad
                frontroomrad
                ameliarad
                dinningroomrad
            /],

        },
    };
}

sub alarm_switches_conf {

    die "alarm_switches_conf NOT YET IMPLEMENTED\n";

    return {

    };
}

1;
