package Khaospy::Constants;
use strict;
use warnings;

use JSON;
use Exporter qw/import/;

use ZMQ::LibZMQ3;

our $PI_GPIO_CMD = "/usr/bin/gpio";
our $PI_I2C_GET  = "/usr/sbin/i2cget";
our $PI_I2C_SET  = "/usr/sbin/i2cset";

our $ZMQ_CONTEXT = zmq_init();
our $JSON = JSON->new->allow_nonref;

sub true  { 1 };
sub false { 0 };

sub ON      { "on"  };
our $ON     = ON();

sub OFF     { "off" };
our $OFF    = OFF();

sub IN {"in"};
our $IN = IN();

sub OUT {"out"};
our $OUT = OUT();

sub STATUS  { "status" };
our $STATUS = STATUS();

sub AUTO   {"auto"};
sub MANUAL {"manual"};

our $CODE_VERSION="0.01.001";



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

# To be much use $PI_CONTROL_MCP23017_PINS_TIMEOUT really needs to be
# greater than the value of $PI_CONTROLLER_DAEMON_TIMER.
# This is because $PI_CONTROLLER_DAEMON_TIMER runs the code that polls
# MCP23017 controls, and therefore making  $PI_CONTROL_MCP23017_PINS_TIMEOUT just a bit bigger means there should be just one poll of MCP23017 port registers.
our $PI_CONTROL_MCP23017_PINS_TIMEOUT = 0.2;

#################
# daemon scripts

our $ONE_WIRE_SENDER            = 'khaospy-one-wired-sender.py';
#our $ONE_WIRE_SENDER_TIMER      =
our $ONE_WIRE_RECEIVER          = 'khaospy-one-wired-receiver.py';
#our $ONE_WIRE_RECEIVER_TIMER    =
our $PI_CONTROLLER_DAEMON       = 'khaospy-pi-controls-d.pl';
our $PI_CONTROLLER_DAEMON_TIMER = .1;

# Polling Orvibo S20s is SLOW.
# If the other-controls-daemon polls with its TIMER too often then
# it seems messages are dropped by zmq, and all the daemon does is poll.
# There is a setting poll_timeout for orvibo S20s that allow the timer-poll to run more # frequently.
our $OTHER_CONTROLS_DAEMON       = 'khaospy-other-controls-d.pl';
our $OTHER_CONTROLS_DAEMON_TIMER = 1;

our $PI_CONTROLLER_QUEUE_DAEMON = 'khaospy-command-queue-d.pl';
our $PI_CONTROLLER_QUEUE_DAEMON_TIMER = .1;

#our $STATUS_DAEMON_PUBLISH_EVERY_SECS               = 2;
#our $RULES_DAEMON_RUN_EVERY_SECS                    = 0.5;

#our $PI_STATUS_DAEMON           =
our $MAC_SWITCH_DAEMON          = 'khaospy-mac-switch-d.pl';
our $MAC_SWITCH_DAEMON_TIMER    = 5;
our $PING_SWITCH_DAEMON         = 'khaospy-ping-switch-d.pl';
our $PING_SWITCH_DAEMON_TIMER   = 5;



our $KHAOSPY_ALL_SCRIPTS = [
    our $KHAOSPY_ONE_WIRED_SENDER_SCRIPT
        = "$KHAOSPY_BIN_DIR/$ONE_WIRE_SENDER",

    our $KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT
        = "$KHAOSPY_BIN_DIR/$ONE_WIRE_RECEIVER",

    our $KHAOSPY_ONE_WIRE_HEATING_DAEMON
        = "$KHAOSPY_BIN_DIR/khaospy-one-wire-heating-daemon.pl",

    our $KHAOSPY_BOILER_DAEMON_SCRIPT
        = "$KHAOSPY_BIN_DIR/khaospy-boiler-daemon.pl",

    our $KHAOSPY_PI_CONTROLLER_DAEMON_SCRIPT
        = "$KHAOSPY_BIN_DIR/$PI_CONTROLLER_DAEMON",

    our $KHAOSPY_OTHER_CONTROLS_DAEMON_SCRIPT
        = "$KHAOSPY_BIN_DIR/$OTHER_CONTROLS_DAEMON",

    our $MAC_SWITCH_DAEMON_SCRIPT
        = "$KHAOSPY_BIN_DIR/$MAC_SWITCH_DAEMON",

    our $PING_SWITCH_DAEMON_SCRIPT
        = "$KHAOSPY_BIN_DIR/$PING_SWITCH_DAEMON",

    our $KHAOSPY_PI_CONTROLLER_QUEUE_DAEMON_SCRIPT
        = "$KHAOSPY_BIN_DIR/$PI_CONTROLLER_QUEUE_DAEMON",
];


#############
# json confs

our $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF   = "heating_thermometer.json";
our $KHAOSPY_CONTROLS_CONF                  = "controls.json";
our $KHAOSPY_BOILERS_CONF                   = "boilers.json";

# TODO KHAOSPY_GLOBAL_CONF to be deprecated. migrate to PI_HOST conf.
our $KHAOSPY_GLOBAL_CONF                    = "global.json";
our $KHAOSPY_PI_HOSTS_CONF                  = "pi-host.json";

our $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF";

our $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_RELOAD_SECS = 300;

our $KHAOSPY_CONTROLS_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_CONTROLS_CONF";

our $KHAOSPY_BOILERS_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_BOILERS_CONF";

# TODO KHAOSPY_GLOBAL_CONF to be deprecated. migrate to PI_HOST conf.
our $KHAOSPY_GLOBAL_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_GLOBAL_CONF";

our $KHAOSPY_PI_HOSTS_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_PI_HOSTS_CONF";

#############
our $HEATING_CONTROL_DAEMON_PUBLISH_PORT  = 5021;

our $ONE_WIRE_DAEMON_PORT                 = 5001;

# TOOD QUEUE_COMMAND_PORT needs renaming to PI_OPERATE_CONTROL_SEND_PORT
# TODO rename $QUEUE_COMMAND_PORT to $QUEUE_COMMAND_PORT
our $QUEUE_COMMAND_PORT                   = 5063;
our $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT = 5061;
our $PI_CONTROLLER_DAEMON_SEND_PORT       = 5062;
our $PI_STATUS_DAEMON_SEND_PORT           = 5064;

our $OTHER_CONTROLS_DAEMON_SEND_PORT      = 5065;

our $MAC_SWITCH_DAEMON_SEND_PORT               = 5005;
our $PING_SWITCH_DAEMON_SEND_PORT              = 5006;

our $MESSAGES_OVER_SECS_INVALID = 3600;
our $MESSAGE_TIMEOUT            = 10; # seconds.
our $ZMQ_REQUEST_TIMEOUT        = 10; # seconds.

our $LOCALHOST = '127.0.0.1';


######################
our @EXPORT_OK = qw(

    $PI_GPIO_CMD
    $PI_I2C_GET
    $PI_I2C_SET

    $ZMQ_CONTEXT
    $JSON

    true false

    IN $IN OUT $OUT

     ON  OFF  STATUS
    $ON $OFF $STATUS

    AUTO MANUAL

    $PI_CONTROL_MCP23017_PINS_TIMEOUT

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

    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_RELOAD_SECS

    $KHAOSPY_CONTROLS_CONF
    $KHAOSPY_CONTROLS_CONF_FULLPATH

    $KHAOSPY_BOILERS_CONF
    $KHAOSPY_BOILERS_CONF_FULLPATH

    $KHAOSPY_GLOBAL_CONF
    $KHAOSPY_GLOBAL_CONF_FULLPATH

    $KHAOSPY_PI_HOSTS_CONF
    $KHAOSPY_PI_HOSTS_CONF_FULLPATH

    $KHAOSPY_ALL_SCRIPTS

    $KHAOSPY_ONE_WIRED_SENDER_SCRIPT
    $KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON
    $KHAOSPY_BOILER_DAEMON_SCRIPT

    $KHAOSPY_PI_CONTROLLER_DAEMON_SCRIPT

    $KHAOSPY_PI_CONTROLLER_QUEUE_DAEMON_SCRIPT

    $MAC_SWITCH_DAEMON
    $MAC_SWITCH_DAEMON_SCRIPT
    $MAC_SWITCH_DAEMON_TIMER
    $MAC_SWITCH_DAEMON_SEND_PORT

    $PING_SWITCH_DAEMON
    $PING_SWITCH_DAEMON_SCRIPT
    $PING_SWITCH_DAEMON_TIMER
    $PING_SWITCH_DAEMON_SEND_PORT

    $ONE_WIRE_SENDER
    $ONE_WIRE_RECEIVER
    $PI_CONTROLLER_DAEMON
    $PI_CONTROLLER_DAEMON_TIMER

    $OTHER_CONTROLS_DAEMON
    $OTHER_CONTROLS_DAEMON_TIMER
    $KHAOSPY_OTHER_CONTROLS_DAEMON_SCRIPT


    $PI_CONTROLLER_QUEUE_DAEMON
    $PI_CONTROLLER_QUEUE_DAEMON_TIMER

    $HEATING_CONTROL_DAEMON_PUBLISH_PORT
    $ONE_WIRE_DAEMON_PORT

    $QUEUE_COMMAND_PORT

    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT
    $OTHER_CONTROLS_DAEMON_SEND_PORT
    $PI_STATUS_DAEMON_SEND_PORT


    $MESSAGES_OVER_SECS_INVALID
    $MESSAGE_TIMEOUT
    $ZMQ_REQUEST_TIMEOUT

    $LOCALHOST

);

1;
