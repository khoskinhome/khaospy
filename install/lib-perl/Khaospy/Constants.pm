package Khaospy::Constants;
use strict;
use warnings;

use JSON;
use Exporter qw/import/;

use ZMQ::LibZMQ3;

our $CODE_VERSION="0.01.001";

our $PI_GPIO_CMD = "/usr/bin/gpio";
our $PI_I2C_GET  = "/usr/sbin/i2cget";
our $PI_I2C_SET  = "/usr/sbin/i2cset";

our $ZMQ_CONTEXT = zmq_init();
our $JSON = JSON->new->allow_nonref;

sub true  { 1 };
sub false { 0 };

our $true  = 1;
our $false = 0;

# binary state controls use ON and OFF in the code.
# the synonyms are translated into the field current_state_trans by DBH::Controls calls
# this is primarily for display in the webui.
# State synonyms are :
# true  == open   == on  == pingable     == 1 == UNLOCKED;
# false == closed == off == not-pingable == 0 == LOCKED;

# actions / states

# on, off
sub ON      { "on"  }; #1
our $ON     = ON();

sub OFF     { "off" }; #0
our $OFF    = OFF();

sub  STATE_TYPE_ON_OFF { "$ON-$OFF" };
our $STATE_TYPE_ON_OFF = STATE_TYPE_ON_OFF();

# open, closed
sub OPEN    { "open"  };  #1
our $OPEN   = OPEN();

sub CLOSED  { "closed" }; #0
our $CLOSED = CLOSED();

sub  STATE_TYPE_OPEN_CLOSED { "$OPEN-$CLOSED" }
our $STATE_TYPE_OPEN_CLOSED = STATE_TYPE_OPEN_CLOSED();

# pingable, not-pingable
sub  PINGABLE { "pingable" }         #1
our $PINGABLE = PINGABLE();

#TODO could go around the code renaming NOT_PINGABLE to UNPINGABLE.
sub  NOT_PINGABLE { "unpingable" } #0
our $NOT_PINGABLE = NOT_PINGABLE();

sub  STATE_TYPE_PINGABLE_NOT_PINGABLE { "$PINGABLE-$NOT_PINGABLE" }
our $STATE_TYPE_PINGABLE_NOT_PINGABLE = STATE_TYPE_PINGABLE_NOT_PINGABLE();

# unlocked, locked
sub  UNLOCKED {"unlocked"}  #1
our $UNLOCKED = UNLOCKED();

sub  LOCKED   {"locked"}    #0
our $LOCKED   = LOCKED();

sub  STATE_TYPE_UNLOCKED_LOCKED { "$UNLOCKED-$LOCKED" }
our $STATE_TYPE_UNLOCKED_LOCKED = STATE_TYPE_UNLOCKED_LOCKED();

sub IN {"in"};
our $IN = IN();

sub OUT {"out"};
our $OUT = OUT();

sub STATUS  { "status" };
our $STATUS = STATUS();

sub  INC_VALUE_ONE { "inc-value-one" };
our $INC_VALUE_ONE = INC_VALUE_ONE;

sub  DEC_VALUE_ONE { "dec-value-one" };
our $DEC_VALUE_ONE = DEC_VALUE_ONE;

# last_change_state_by is one of these :
sub AUTO   {"auto"};
our $AUTO  = AUTO;

sub MANUAL  {"manual"};
our $MANUAL = MANUAL;

sub WEBUI  {"webui"};
our $WEBUI = WEBUI;

sub RULESD  {"rulesd"};
our $RULESD = RULESD;


#######################
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

our $ONE_WIRE_SENDER_PERL_DAEMON = 'khaospy-one-wire-daemon.pl';
our $ONE_WIRE_SENDER_PERL_TIMER  = 30; # this is how often one-wire-temperature sensors are polled in seconds.
our $ONE_WIRE_SENSOR_DIR         = '/sys/bus/w1/devices/';

our $RULES_DAEMON               = 'khaospy-rules-d.pl';
our $RULES_DAEMON_TIMER         = 10; # how often the rules are checked in seconds.

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

our $PI_STATUS_DAEMON                     = 'khaospy-status-d.pl';
our $PI_STATUS_DAEMON_TIMER               = 120;
our $PI_STATUS_DAEMON_WEBUI_VAR_TIMER     = 5;
our $PI_STATUS_DAEMON_WEBUI_VAR_PUB_COUNT = 3;
our $PI_STATUS_RRD_UPDATE_TIMEOUT         = 120;

# MAC_SWITCH ARGS and TIMER can be overridden with
# CLI options to the khaospy-mac-switch-d.pl script
our $MAC_SWITCH_NMAP_ARGS       = '-sP -PE -PA21,23,80,3389';
our $MAC_SWITCH_DAEMON          = 'khaospy-mac-switch-d.pl';
our $MAC_SWITCH_DAEMON_TIMER    = 60; #nmap-ing 256 address takes 8 ish seconds
our $NMAP_EXECUTABLE            = '/usr/bin/nmap';

our $ERROR_LOG_DAEMON           = 'khaospy-error-log-d.pl';
our $ERROR_LOG_DAEMON_TIMER     = 5;

our $TIMER_AFTER_COMMON = 0.1; # secs. The time after which a Daemon timed sub first starts.

our $ALL_SCRIPTS = [
    our $ONE_WIRE_SENDER_PERL_SCRIPT
        = "$BIN_DIR/$ONE_WIRE_SENDER_PERL_DAEMON",

    our $RULES_DAEMON_SCRIPT
        = "$BIN_DIR/$RULES_DAEMON",

    our $HEATING_DAEMON_SCRIPT
        = "$BIN_DIR/khaospy-heating-daemon.pl",

    our $BOILER_DAEMON_SCRIPT
        = "$BIN_DIR/khaospy-boiler-daemon.pl",

    our $PI_CONTROLLER_DAEMON_SCRIPT
        = "$BIN_DIR/$PI_CONTROLLER_DAEMON",

    our $OTHER_CONTROLS_DAEMON_SCRIPT
        = "$BIN_DIR/$OTHER_CONTROLS_DAEMON",

    our $MAC_SWITCH_DAEMON_SCRIPT
        = "$BIN_DIR/$MAC_SWITCH_DAEMON",

    our $PI_STATUS_DAEMON_SCRIPT
        = "$BIN_DIR/$PI_STATUS_DAEMON",

    our $COMMAND_QUEUE_DAEMON_SCRIPT
        = "$BIN_DIR/$COMMAND_QUEUE_DAEMON",

    our $ERROR_LOG_DAEMON_SCRIPT
        = "$BIN_DIR/$ERROR_LOG_DAEMON",
];

#############
# json confs

our $HEATING_DAEMON_CONF            = "heating_thermometer.json";
our $RULES_DAEMON_CONF              = "rules.json";
our $CONTROLS_CONF                  = "controls.json";
our $BOILERS_CONF                   = "boilers.json";

# TODO KHAOSPY_GLOBAL_CONF to be deprecated. migrate to PI_HOST conf.
our $GLOBAL_CONF                    = "global.json";
our $DATABASE_CONF                  = "database.json";
our $EMAIL_CONF                     = "email.json";
our $PI_HOSTS_CONF                  = "pi-host.json";

our $HEATING_DAEMON_CONF_FULLPATH
    = "$CONF_DIR/$HEATING_DAEMON_CONF";

our $HEATING_DAEMON_CONF_RELOAD_SECS = 300;

our $RULES_DAEMON_CONF_FULLPATH
    = "$CONF_DIR/$RULES_DAEMON_CONF";

our $RULES_DAEMON_RELOAD_SECS = 300;

our $CONTROLS_CONF_FULLPATH
    = "$CONF_DIR/$CONTROLS_CONF";

our $BOILERS_CONF_FULLPATH
    = "$CONF_DIR/$BOILERS_CONF";

# TODO KHAOSPY_GLOBAL_CONF to be deprecated. migrate to PI_HOST conf.
our $GLOBAL_CONF_FULLPATH
    = "$CONF_DIR/$GLOBAL_CONF";

our $DATABASE_CONF_FULLPATH
    = "$CONF_DIR/$DATABASE_CONF";

our $EMAIL_CONF_FULLPATH
    = "$CONF_DIR/$EMAIL_CONF";

our $PI_HOSTS_CONF_FULLPATH
    = "$CONF_DIR/$PI_HOSTS_CONF";

#############
# TODO . almost certainly don't need this , post the boiler daemon rewrite.
our $HEATING_CONTROL_DAEMON_PUBLISH_PORT  = 5021;

our $ONE_WIRE_DAEMON_PERL_PORT            = 5002;

# TOOD QUEUE_COMMAND_PORT needs renaming to PI_OPERATE_CONTROL_SEND_PORT
# TODO rename $QUEUE_COMMAND_PORT to $QUEUE_COMMAND_PORT
our $QUEUE_COMMAND_PORT                   = 5063;
our $COMMAND_QUEUE_DAEMON_SEND_PORT       = 5061;
our $PI_CONTROLLER_DAEMON_SEND_PORT       = 5062;
our $PI_STATUS_DAEMON_SEND_PORT           = 5064;

our $OTHER_CONTROLS_DAEMON_SEND_PORT      = 5065;

our $MAC_SWITCH_DAEMON_SEND_PORT          = 5005;

our $ERROR_LOG_DAEMON_SEND_PORT           = 5066;

our $MESSAGES_OVER_SECS_INVALID = 3600;
our $MESSAGE_TIMEOUT            = 10; # seconds.
our $ZMQ_REQUEST_TIMEOUT        = 10; # seconds.

our $LOCALHOST = '127.0.0.1';

our $BOILER_DAEMON_TIMER = 5;
our $BOILER_STATUS_REFRESH_EVERY_SECS = 120;
our $BOILER_DAEMON_DELAY_START = 20;

#################
# CONTROL_TYPES :
our $ORVIBOS20_CONTROL_TYPE                 = "orvibos20";
our $ONEWIRE_THERM_CONTROL_TYPE             = "onewire-thermometer";

our $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE      = "pi-gpio-relay-manual";
our $PI_GPIO_RELAY_CONTROL_TYPE             = "pi-gpio-relay";
our $PI_GPIO_SWITCH_CONTROL_TYPE            = "pi-gpio-switch";

our $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE  = "pi-mcp23017-relay-manual";
our $PI_MCP23017_RELAY_CONTROL_TYPE         = "pi-mcp23017-relay";
our $PI_MCP23017_SWITCH_CONTROL_TYPE        = "pi-mcp23017-switch";

our $WEBUI_VAR_FLOAT_CONTROL_TYPE           = "webui-var-float",
our $WEBUI_VAR_INTEGER_CONTROL_TYPE         = "webui-var-integer",
our $WEBUI_VAR_STRING_CONTROL_TYPE          = "webui-var-string",

#our $WEBUI_VAR_ON_OFF_CONTROL_TYPE          = "webui-var-on-off",
#our $WEBUI_VAR_MULTI_ON_OFF_CONTROL_TYPE    = "webui-var-multi-on-off",

# VAR_DIMMABLE is a float between 0 and 1 ( for dimmable controls ).
#our $WEBUI_VAR_DIMMABLE_CONTROL_TYPE        = "webui-var-dimmable",
#our $WEBUI_VAR_MULTI_DIMMABLE_CONTROL_TYPE  = "webui-var-multi-dimmable",

#our $WEBUI_VAR_DATETIME_TZ_CONTROL_TYPE     = "webui-var-datetime-tz",
#our $WEBUI_VAR_DATE_CONTROL_TYPE            = "webui-var-date",
#our $WEBUI_VAR_TIME_CONTROL_TYPE            = "webui-var-time",
#our $WEBUI_VAR_INTERVAL_CONTROL_TYPE        = "webui-var-interval",
#our $WEBUI_VAR_HOURS_CONTROL_TYPE           = "webui-var-hours",
#our $WEBUI_VAR_MINS_CONTROL_TYPE            = "webui-var-mins",

our $WEBUI_ALL_CONTROL_TYPES = {
    $WEBUI_VAR_FLOAT_CONTROL_TYPE           => true,
    $WEBUI_VAR_INTEGER_CONTROL_TYPE         => true,
    $WEBUI_VAR_STRING_CONTROL_TYPE          => true,

    #$WEBUI_VAR_ON_OFF_CONTROL_TYPE          => true,
    #$WEBUI_VAR_MULTI_ON_OFF_CONTROL_TYPE   => true,

    #$WEBUI_VAR_DIMMABLE_CONTROL_TYPE       => true,
    #$WEBUI_VAR_MULTI_DIMMABLE_CONTROL_TYPE => true,

    #$WEBUI_VAR_DATETIME_TZ_CONTROL_TYPE     => true,
    #$WEBUI_VAR_DATE_CONTROL_TYPE            => true,
    #$WEBUI_VAR_TIME_CONTROL_TYPE            => true,
    #$WEBUI_VAR_INTERVAL_CONTROL_TYPE        => true,
    #$WEBUI_VAR_HOURS_CONTROL_TYPE           => true,
    #$WEBUI_VAR_MINS_CONTROL_TYPE            => true,
};

our $MAC_SWITCH_CONTROL_TYPE                = "mac-switch";
our $MAC_SWITCH_CONTROL_SUB_TYPE_PHONE      = "phone";     # mobile phones
our $MAC_SWITCH_CONTROL_SUB_TYPE_SERVER     = "server";    # server machines.
our $MAC_SWITCH_CONTROL_SUB_TYPE_PC         = "pc";        # laptops / PCs / tablets / user machines.
our $MAC_SWITCH_CONTROL_SUB_TYPE_AV         = "av";        # TVs / Blurays / game-consoles / Chromecast / PVRs
our $MAC_SWITCH_CONTROL_SUB_TYPE_NETWORK    = "network";   # networking equipment.
our $MAC_SWITCH_CONTROL_SUB_TYPE_HOME_AUTO  = "home-auto"; # for Orvibo S20 type things.
our $MAC_SWITCH_CONTROL_SUB_TYPE_PRINTER    = "printer";   # printers
our $MAC_SWITCH_CONTROL_SUB_TYPE_CCTV       = "cctv";      # ip cctv cameras

our $MAC_SWITCH_CONTROL_SUB_TYPE_ALL = {
    $MAC_SWITCH_CONTROL_SUB_TYPE_PHONE    =>1,
    $MAC_SWITCH_CONTROL_SUB_TYPE_SERVER   =>1,
    $MAC_SWITCH_CONTROL_SUB_TYPE_PC       =>1,
    $MAC_SWITCH_CONTROL_SUB_TYPE_AV       =>1,
    $MAC_SWITCH_CONTROL_SUB_TYPE_NETWORK  =>1,
    $MAC_SWITCH_CONTROL_SUB_TYPE_HOME_AUTO=>1,
    $MAC_SWITCH_CONTROL_SUB_TYPE_PRINTER  =>1,
    $MAC_SWITCH_CONTROL_SUB_TYPE_CCTV     =>1,
};

our $SCRIPT_TO_PORT = {
    $ONE_WIRE_SENDER_PERL_SCRIPT
        => $ONE_WIRE_DAEMON_PERL_PORT,

    $PI_CONTROLLER_DAEMON_SCRIPT
        => $PI_CONTROLLER_DAEMON_SEND_PORT,

    $OTHER_CONTROLS_DAEMON_SCRIPT
        => $OTHER_CONTROLS_DAEMON_SEND_PORT,

    $MAC_SWITCH_DAEMON_SCRIPT
        => $MAC_SWITCH_DAEMON_SEND_PORT,

    $PI_STATUS_DAEMON_SCRIPT
        => $PI_STATUS_DAEMON_SEND_PORT,
};

# These are the DEFAULTS. Can be overridden in khaospy-status-d.pl
our $DB_CONTROL_STATUS_DAYS_HISTORY = '365';
our $DB_CONTROL_STATUS_PURGE_TIMEOUT_SECS = 3600;

######################
our @EXPORT_OK = qw(

    $PI_GPIO_CMD
    $PI_I2C_GET
    $PI_I2C_SET

    $ZMQ_CONTEXT
    $JSON

    IN $IN OUT $OUT

    true  $true  OPEN   $OPEN   ON  $ON  PINGABLE     $PINGABLE     UNLOCKED $UNLOCKED
    false $false CLOSED $CLOSED OFF $OFF NOT_PINGABLE $NOT_PINGABLE LOCKED   $LOCKED

    $STATE_TYPE_ON_OFF                STATE_TYPE_ON_OFF
    $STATE_TYPE_OPEN_CLOSED           STATE_TYPE_OPEN_CLOSED
    $STATE_TYPE_PINGABLE_NOT_PINGABLE STATE_TYPE_PINGABLE_NOT_PINGABLE
    $STATE_TYPE_UNLOCKED_LOCKED       STATE_TYPE_UNLOCKED_LOCKED

    STATUS $STATUS

     INC_VALUE_ONE  DEC_VALUE_ONE
    $INC_VALUE_ONE $DEC_VALUE_ONE

     AUTO  MANUAL  WEBUI  RULESD
    $AUTO $MANUAL $WEBUI $RULESD

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


    $RULES_DAEMON
    $RULES_DAEMON_TIMER
    $RULES_DAEMON_SCRIPT
    $RULES_DAEMON_CONF
    $RULES_DAEMON_CONF_FULLPATH
    $RULES_DAEMON_RELOAD_SECS

    $HEATING_DAEMON_CONF
    $HEATING_DAEMON_CONF_FULLPATH
    $HEATING_DAEMON_CONF_RELOAD_SECS

    $CONTROLS_CONF
    $CONTROLS_CONF_FULLPATH

    $BOILERS_CONF
    $BOILERS_CONF_FULLPATH

    $GLOBAL_CONF
    $GLOBAL_CONF_FULLPATH

    $DATABASE_CONF
    $DATABASE_CONF_FULLPATH

    $EMAIL_CONF
    $EMAIL_CONF_FULLPATH

    $PI_HOSTS_CONF
    $PI_HOSTS_CONF_FULLPATH

    $ALL_SCRIPTS

    $ONE_WIRE_SENDER_PERL_DAEMON
    $ONE_WIRE_SENDER_PERL_SCRIPT
    $ONE_WIRE_DAEMON_PERL_PORT
    $ONE_WIRE_SENDER_PERL_TIMER
    $ONE_WIRE_SENSOR_DIR

    $HEATING_DAEMON_SCRIPT
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
    $MAC_SWITCH_NMAP_ARGS
    $NMAP_EXECUTABLE

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
    $PI_STATUS_DAEMON_WEBUI_VAR_TIMER
    $PI_STATUS_DAEMON_WEBUI_VAR_PUB_COUNT
    $PI_STATUS_DAEMON_SCRIPT
    $PI_STATUS_DAEMON_SEND_PORT
    $PI_STATUS_RRD_UPDATE_TIMEOUT

    $TIMER_AFTER_COMMON

    $QUEUE_COMMAND_PORT

    MTYPE_QUEUE_COMMAND
    MTYPE_POLL_UPDATE
    MYTPE_COMMAND_QUEUE_BROADCAST
    MTYPE_OPERATION_STATUS

    $MESSAGES_OVER_SECS_INVALID
    $MESSAGE_TIMEOUT
    $ZMQ_REQUEST_TIMEOUT

    $LOCALHOST

    $ORVIBOS20_CONTROL_TYPE
    $ONEWIRE_THERM_CONTROL_TYPE
    $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE
    $PI_GPIO_RELAY_CONTROL_TYPE
    $PI_GPIO_SWITCH_CONTROL_TYPE
    $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE
    $PI_MCP23017_RELAY_CONTROL_TYPE
    $PI_MCP23017_SWITCH_CONTROL_TYPE
    $MAC_SWITCH_CONTROL_TYPE

    $WEBUI_ALL_CONTROL_TYPES
    $WEBUI_VAR_FLOAT_CONTROL_TYPE
    $WEBUI_VAR_INTEGER_CONTROL_TYPE
    $WEBUI_VAR_STRING_CONTROL_TYPE


    $MAC_SWITCH_CONTROL_SUB_TYPE_PHONE
    $MAC_SWITCH_CONTROL_SUB_TYPE_SERVER
    $MAC_SWITCH_CONTROL_SUB_TYPE_PC
    $MAC_SWITCH_CONTROL_SUB_TYPE_AV
    $MAC_SWITCH_CONTROL_SUB_TYPE_NETWORK
    $MAC_SWITCH_CONTROL_SUB_TYPE_HOME_AUTO
    $MAC_SWITCH_CONTROL_SUB_TYPE_PRINTER
    $MAC_SWITCH_CONTROL_SUB_TYPE_CCTV

    $MAC_SWITCH_CONTROL_SUB_TYPE_ALL

    $SCRIPT_TO_PORT

    $DB_CONTROL_STATUS_DAYS_HISTORY
    $DB_CONTROL_STATUS_PURGE_TIMEOUT_SECS

    $ERROR_LOG_DAEMON
    $ERROR_LOG_DAEMON_SCRIPT
    $ERROR_LOG_DAEMON_SEND_PORT
    $ERROR_LOG_DAEMON_TIMER

);

1;
