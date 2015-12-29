package Khaospy::Constants;
use strict;
use warnings;

# install/bin/testrig-lighting-on-off-2relay-automated-with-detect.pl:sub burp {

use Exporter qw/import/;

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

our $KHAOSPY_HEATING_CONTROL_SCRIPT
    = "$KHAOSPY_BIN_DIR/khaospy-heating-control.pl";

#############
# json confs
our $KHAOSPY_ALL_CONFS = {
    our $KHAOSPY_DAEMON_RUNNER_CONF
        = "daemon-runner.json"       => daemon_runner_conf(),
    our $KHAOSPY_HEATING_THERMOMETER_CONF
        = "heating_thermometer.json" => heating_thermometer_config(),
    our $KHAOSPY_CONTROLS_CONF
        = "controls.json"            => controls_conf(),
};

our $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_DAEMON_RUNNER_CONF";

our $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_HEATING_THERMOMETER_CONF";

our $KHAOSPY_CONTROLS_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_CONTROLS_CONF";

#############

our @EXPORT_OK = qw(

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
    $KHAOSPY_HEATING_THERMOMETER_CONF
    $KHAOSPY_CONTROLS_CONF

    $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $KHAOSPY_CONTROLS_CONF_FULLPATH

    $KHAOSPY_ONE_WIRED_SENDER_SCRIPT
    $KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT
    $KHAOSPY_HEATING_CONTROL_SCRIPT
);

#for my $dir ( @$KHAOSPY_ALL_DIRS ){
#    if ( ! -d $dir ) {
#        system("mkdir -p $dir") && print "Can't create dir $dir\n";
#    }
#}

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
    #        "$KHAOSPY_HEATING_CONTROL_SCRIPT",
        ],
    #    piserver2 => [
    #    ],
        piloft => [
            "$KHAOSPY_ONE_WIRED_SENDER_SCRIPT --stdout_freq=890",
            "/opt/khaospy/bin/khaospy-amelia-hackit-daemon.pl",
        ],
        piold => [
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
#           lower_temp         => 20, # when temp is less than this, the "on" command will be sent.
#                               if any of the switches are open an "off" command will be sent.
#           turn_on_command    => command to switch on heating,
#           turn_off_command   => command to switch off heating',
#           get_status_command => command to get current status',

# commands are in the format "<name> <action>" where :
#   <name> is the name of the controller
#   <action> is "on" "off" or "status"

#       OPTIONAL-KEYS that can be supplied with the turn-off-off ones above :
#           closed_switches    => Array of swtiches that must be closed for "on" command.
#
# TODO , not sure if I need the get_status_command in this config. TO BE DECIDED.
#
sub heating_thermometer_config {
    return {
        '28-0000066ebc74' => {
            name               => 'Alison',
            rrd_group          => 'upstairs',
            upper_temp         => 22,
            lower_temp         => 20,
            closed_switches    => [],
            turn_on_command    => 'alisonrad on',
            turn_off_command   => 'alisonrad off',
            get_status_command => 'alisonrad status',
        },
        '28-000006e04e8b' => {
            name               => 'Playhouse-tv',
            rrd_group          => 'outside',
        },
        '28-0000066fe99e' => {
            name               => 'Playhouse-9e-door',
            rrd_group          => 'outside',
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
            upper_temp         => 22,
            lower_temp         => 20,
            closed_switches    => [],
            turn_on_command    => 'ameliarad on',
            turn_off_command   => 'ameliarad off',
            get_status_command => 'ameliarad status',
        },
        '28-021463423bff' => {
            name               => 'Upstairs-Landing',
            rrd_group          => 'upstairs',
        },
    };
}

#################################
# controls_conf
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
            mac  => 'AC-CF-23-72-F3-D4'
        },
        karlrad         => {
            type => "orviboS20",
            host => 'karlrad',
            mac  => 'AC-CF-23-8D-7E-D2'
        },
        dinningroomrad  => {
            type => "orviboS20",
            host => 'dinningroomrad',
            mac  => 'AC-CF-23-8D-A4-8E'
        },
        frontroomrad    => {
            type => "orviboS20",
            host => 'frontroomrad',
            mac  => 'AC-CF-23-8D-3B-96'
        },
    };
}

1;
