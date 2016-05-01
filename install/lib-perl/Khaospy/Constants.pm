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

sub MTYPE_QUEUE_COMMAND           {"queue-command"};
sub MTYPE_POLL_UPDATE             {"poll-update"};
sub MYTPE_COMMAND_QUEUE_BROADCAST {"command-queue-broadcast"};
sub MTYPE_OPERATION_STATUS        {"operation-status"};
#######
# dirs

our $ALL_DIRS = [
    our $ROOT_DIR      = "/opt/khaospy",
    our $BIN_DIR       = "$ROOT_DIR/bin",
    our $CONF_DIR      = "$ROOT_DIR/conf",
    our $LIB_PERL      = "$ROOT_DIR/lib-perl",
    our $LIB_PERL_T    = "$ROOT_DIR/lib-perl-t",
    our $LOG_DIR       = "$ROOT_DIR/log",
    our $PID_DIR       = "$ROOT_DIR/pid",
    our $RRD_DIR       = "$ROOT_DIR/rrd",
    our $RRD_IMAGE_DIR = "$ROOT_DIR/rrdimage",
    our $WWW_DIR       = "$ROOT_DIR/www",
    our $WWW_BIN_DIR   = "$ROOT_DIR/www-bin",
];

# To be much use $PI_CONTROL_MCP23017_PINS_TIMEOUT really needs to be
# greater than the value of $PI_CONTROLLER_DAEMON_TIMER.
# This is because $PI_CONTROLLER_DAEMON_TIMER runs the code that polls
# MCP23017 controls, and therefore making  $PI_CONTROL_MCP23017_PINS_TIMEOUT just a bit bigger means there should be just one poll of MCP23017 port registers.
our $PI_CONTROL_MCP23017_PINS_TIMEOUT = 0.3;

#################
# daemon scripts

our $ONE_WIRE_SENDER            = 'khaospy-one-wired-sender.py';
#our $ONE_WIRE_SENDER_TIMER      =
our $ONE_WIRE_RECEIVER          = 'khaospy-one-wired-receiver.py';
#our $ONE_WIRE_RECEIVER_TIMER    =

our $ONE_WIRE_SENDER_PERL_DAEMON = 'khaospy-one-wire-daemon.pl';
our $ONE_WIRE_SENDER_PERL_TIMER  = 30;
our $ONE_WIRE_SENSOR_DIR         = '/sys/bus/w1/devices/';

our $PI_CONTROLLER_DAEMON       = 'khaospy-pi-controls-d.pl';
our $PI_CONTROLLER_DAEMON_TIMER = .2;

# Polling Orvibo S20s is SLOW.
# If the other-controls-daemon polls with its TIMER too often then
# it seems messages are dropped by zmq, and all the daemon does is poll.
# This seems to be due to network-traffic issues.
# There is a setting poll_timeout for orvibo S20s that allow the timer-poll to run more # frequently.
# It is recommend to set the poll_timeout on these to about 5 secs.
our $OTHER_CONTROLS_DAEMON       = 'khaospy-other-controls-d.pl';
our $OTHER_CONTROLS_DAEMON_TIMER = 1;

our $COMMAND_QUEUE_DAEMON = 'khaospy-command-queue-d.pl';
our $COMMAND_QUEUE_DAEMON_TIMER = 0.2;
our $COMMAND_QUEUE_DAEMON_BROADCAST_TIMER = 1.6;

#our $STATUS_DAEMON_PUBLISH_EVERY_SECS               = 2;
#our $RULES_DAEMON_RUN_EVERY_SECS                    = 0.5;

our $PI_STATUS_DAEMON           = 'khaospy-status-d.pl';
# TODO : does status-d need a timer ?
# it just will subscribe to all publishers, and to an http-api port.
# its primary mission is for the webui to be able to get the status of controls.
our $PI_STATUS_DAEMON_TIMER     = 5;

our $MAC_SWITCH_DAEMON          = 'khaospy-mac-switch-d.pl';
our $MAC_SWITCH_DAEMON_TIMER    = 5;
our $PING_SWITCH_DAEMON         = 'khaospy-ping-switch-d.pl';
our $PING_SWITCH_DAEMON_TIMER   = 5;

our $ALL_SCRIPTS = [
    our $ONE_WIRED_SENDER_SCRIPT
        = "$BIN_DIR/$ONE_WIRE_SENDER",

    our $ONE_WIRE_SENDER_PERL_SCRIPT
        = "$BIN_DIR/$ONE_WIRE_SENDER_PERL_DAEMON",

    our $ONE_WIRED_RECEIVER_SCRIPT
        = "$BIN_DIR/$ONE_WIRE_RECEIVER",

    our $HEATING_DAEMON
        = "$BIN_DIR/khaospy-heating-daemon.pl",

    our $BOILER_DAEMON_SCRIPT
        = "$BIN_DIR/khaospy-boiler-daemon.pl",

    our $PIBOILER_HOMEEASY_SCHEDULE_DAEMON_SCRIPT
        = "$BIN_DIR/khaospy-piboiler-homeeasy-schedule-d.pl",

    our $PI_CONTROLLER_DAEMON_SCRIPT
        = "$BIN_DIR/$PI_CONTROLLER_DAEMON",

    our $OTHER_CONTROLS_DAEMON_SCRIPT
        = "$BIN_DIR/$OTHER_CONTROLS_DAEMON",

    our $MAC_SWITCH_DAEMON_SCRIPT
        = "$BIN_DIR/$MAC_SWITCH_DAEMON",

    our $PING_SWITCH_DAEMON_SCRIPT
        = "$BIN_DIR/$PING_SWITCH_DAEMON",

    our $PI_STATUS_DAEMON_SCRIPT
        = "$BIN_DIR/$PI_STATUS_DAEMON",

    our $COMMAND_QUEUE_DAEMON_SCRIPT
        = "$BIN_DIR/$COMMAND_QUEUE_DAEMON",
];


#############
# json confs

our $HEATING_DAEMON_CONF   = "heating_thermometer.json";
our $CONTROLS_CONF                  = "controls.json";
our $BOILERS_CONF                   = "boilers.json";

# TODO KHAOSPY_GLOBAL_CONF to be deprecated. migrate to PI_HOST conf.
our $GLOBAL_CONF                    = "global.json";
our $PI_HOSTS_CONF                  = "pi-host.json";

our $HEATING_DAEMON_CONF_FULLPATH
    = "$CONF_DIR/$HEATING_DAEMON_CONF";

our $HEATING_DAEMON_CONF_RELOAD_SECS = 300;

our $CONTROLS_CONF_FULLPATH
    = "$CONF_DIR/$CONTROLS_CONF";

our $BOILERS_CONF_FULLPATH
    = "$CONF_DIR/$BOILERS_CONF";

# TODO KHAOSPY_GLOBAL_CONF to be deprecated. migrate to PI_HOST conf.
our $GLOBAL_CONF_FULLPATH
    = "$CONF_DIR/$GLOBAL_CONF";

our $PI_HOSTS_CONF_FULLPATH
    = "$CONF_DIR/$PI_HOSTS_CONF";

#############
# TODO . almost certainly don't need this , post the boiler daemon rewrite.
our $HEATING_CONTROL_DAEMON_PUBLISH_PORT  = 5021;

our $ONE_WIRE_DAEMON_PORT                 = 5001;
our $ONE_WIRE_DAEMON_PERL_PORT            = 5002;

# TOOD QUEUE_COMMAND_PORT needs renaming to PI_OPERATE_CONTROL_SEND_PORT
# TODO rename $QUEUE_COMMAND_PORT to $QUEUE_COMMAND_PORT
our $QUEUE_COMMAND_PORT                   = 5063;
our $COMMAND_QUEUE_DAEMON_SEND_PORT = 5061;
our $PI_CONTROLLER_DAEMON_SEND_PORT       = 5062;
our $PI_STATUS_DAEMON_SEND_PORT           = 5064;

our $OTHER_CONTROLS_DAEMON_SEND_PORT      = 5065;

our $MAC_SWITCH_DAEMON_SEND_PORT               = 5005;
our $PING_SWITCH_DAEMON_SEND_PORT              = 5006;

our $MESSAGES_OVER_SECS_INVALID = 3600;
our $MESSAGE_TIMEOUT            = 10; # seconds.
our $ZMQ_REQUEST_TIMEOUT        = 10; # seconds.

our $LOCALHOST = '127.0.0.1';

our $BOILER_DAEMON_TIMER = 5;
our $BOILER_STATUS_REFRESH_EVERY_SECS = 120;
our $BOILER_DAEMON_DELAY_START = 20;



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

    $ALL_DIRS
    $ROOT_DIR
    $BIN_DIR
    $CONF_DIR
    $LIB_PERL
    $LIB_PERL_T
    $LOG_DIR
    $PID_DIR
    $RRD_DIR
    $RRD_IMAGE_DIR
    $WWW_DIR
    $WWW_BIN_DIR


    $HEATING_DAEMON_CONF
    $HEATING_DAEMON_CONF_FULLPATH
    $HEATING_DAEMON_CONF_RELOAD_SECS

    $CONTROLS_CONF
    $CONTROLS_CONF_FULLPATH

    $BOILERS_CONF
    $BOILERS_CONF_FULLPATH

    $GLOBAL_CONF
    $GLOBAL_CONF_FULLPATH

    $PI_HOSTS_CONF
    $PI_HOSTS_CONF_FULLPATH

    $ALL_SCRIPTS

    $ONE_WIRE_RECEIVER
    $ONE_WIRED_RECEIVER_SCRIPT

    $ONE_WIRE_SENDER
    $ONE_WIRED_SENDER_SCRIPT
    $ONE_WIRE_DAEMON_PORT

    $ONE_WIRE_SENDER_PERL_DAEMON
    $ONE_WIRE_SENDER_PERL_SCRIPT
    $ONE_WIRE_DAEMON_PERL_PORT
    $ONE_WIRE_SENDER_PERL_TIMER
    $ONE_WIRE_SENSOR_DIR


    $HEATING_DAEMON
    $HEATING_CONTROL_DAEMON_PUBLISH_PORT

    $BOILER_DAEMON_SCRIPT
    $BOILER_DAEMON_TIMER
    $BOILER_STATUS_REFRESH_EVERY_SECS
    $BOILER_DAEMON_DELAY_START


    $COMMAND_QUEUE_DAEMON
    $COMMAND_QUEUE_DAEMON_SCRIPT
    $COMMAND_QUEUE_DAEMON_SEND_PORT
    $COMMAND_QUEUE_DAEMON_TIMER
    $COMMAND_QUEUE_DAEMON_BROADCAST_TIMER

    $MAC_SWITCH_DAEMON
    $MAC_SWITCH_DAEMON_SEND_PORT
    $MAC_SWITCH_DAEMON_SCRIPT
    $MAC_SWITCH_DAEMON_TIMER

    $OTHER_CONTROLS_DAEMON
    $OTHER_CONTROLS_DAEMON_SCRIPT
    $OTHER_CONTROLS_DAEMON_SEND_PORT
    $OTHER_CONTROLS_DAEMON_TIMER

    $PI_CONTROLLER_DAEMON
    $PI_CONTROLLER_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SCRIPT
    $PI_CONTROLLER_DAEMON_TIMER

    $PI_STATUS_DAEMON
    $PI_STATUS_DAEMON_TIMER
    $PI_STATUS_DAEMON_SCRIPT
    $PI_STATUS_DAEMON_SEND_PORT

    $PING_SWITCH_DAEMON
    $PING_SWITCH_DAEMON_SEND_PORT
    $PING_SWITCH_DAEMON_SCRIPT
    $PING_SWITCH_DAEMON_TIMER

    $PIBOILER_HOMEEASY_SCHEDULE_DAEMON_SCRIPT

    $QUEUE_COMMAND_PORT

    MTYPE_QUEUE_COMMAND
    MTYPE_POLL_UPDATE
    MYTPE_COMMAND_QUEUE_BROADCAST
    MTYPE_OPERATION_STATUS

    $MESSAGES_OVER_SECS_INVALID
    $MESSAGE_TIMEOUT
    $ZMQ_REQUEST_TIMEOUT

    $LOCALHOST

);

1;
