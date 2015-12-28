package Khaospy::Constants;
use strict;
use warnings;

# install/bin/testrig-lighting-on-off-2relay-automated-with-detect.pl:sub burp {

use Exporter qw/import/;

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

our $KHAOSPY_ALL_CONFS = {
    our $KHAOSPY_DAEMON_RUNNER_CONF
        = "daemon-runner.json"       => daemon_runner_conf(),
    our $KHAOSPY_HEATING_THERMOMETER_CONF
        = "heating_thermometer.json" => heating_thermometer_config(),
    our $KHAOSPY_ORVIBO_S20_CONF
        = "orvibo_s20_config.json"   => orvibo_s20_config(),
};

our $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_DAEMON_RUNNER_CONF";

our $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_HEATING_THERMOMETER_CONF";

our $KHAOSPY_ORVIBO_S20_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_ORVIBO_S20_CONF";


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

    $KHAOSPY_DAEMON_RUNNER_CONF
    $KHAOSPY_HEATING_THERMOMETER_CONF
    $KHAOSPY_ORVIBO_S20_CONF
    $KHAOSPY_ALL_CONFS

    $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    $KHAOSPY_HEATING_THERMOMETER_CONF_FULLPATH
    $KHAOSPY_ORVIBO_S20_CONF_FULLPATH

);

for my $dir ( @$KHAOSPY_ALL_DIRS ){
    if ( ! -d $dir ) {
        system("mkdir -p $dir") && print "Can't create dir $dir\n";
    }
}

###############################################################################
# "conf" subs

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

#       OPTIONAL-KEYS that can be supplied with the turn-off-off ones above :
#           closed_switches    => Array of swtiches that must be closed for "on" command.
sub heating_thermometer_config {
    return {
        '28-0000066ebc74' => {
            name               => 'Alison',
            rrd_group          => 'upstairs',
            upper_temp         => 22,
            lower_temp         => 20,
            closed_switches    => [],
            turn_on_command    => 'orviboS20 alisonrad on',
            turn_off_command   => 'orviboS20 alisonrad off',
            get_status_command => 'orviboS20 alisonrad status',
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
            turn_on_command    => 'orviboS20 ameliarad on',
            turn_off_command   => 'orviboS20 ameliarad off',
            get_status_command => 'orviboS20 ameliarad status',
        },
        '28-021463423bff' => {
            name               => 'Upstairs-Landing',
            rrd_group          => 'upstairs',
        },
    };
}

sub orvibo_s20_config {
    ## TODO find a way of using the host name from /etc/hosts to get the ip and mac.
    return {
        alisonrad       => { ip => '192.168.1.161', mac => 'AC:CF:23:72:D1:FE' },
        ameliarad       => { ip => '192.168.1.160', mac => 'AC-CF-23-72-F3-D4' },
        karlrad         => { ip => '192.168.1.163', mac => 'AC-CF-23-8D-7E-D2' },
        dinningroomrad  => { ip => '192.168.1.162', mac => 'AC-CF-23-8D-A4-8E' },
        frontroomrad    => { ip => '192.168.1.164', mac => 'AC-CF-23-8D-3B-96' },
    };
}

1;
