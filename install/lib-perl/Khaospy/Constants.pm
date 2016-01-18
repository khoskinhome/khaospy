package Khaospy::Constants;
use strict;
use warnings;

# install/bin/testrig-lighting-on-off-2relay-automated-with-detect.pl:sub burp {

use Exporter qw/import/;

use ZMQ::LibZMQ3;
our $ZMQ_CONTEXT = zmq_init();

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

our $KHAOSPY_PI_CONTROLLER_DAEMON_SCRIPT
    = "$KHAOSPY_BIN_DIR/khaospy-controller-daemon.pl";

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
    our $KHAOSPY_PI_CONTROLLER_CONF
        = "pi_controller.json"          => pi_controller_daemon(),
};

our $KHAOSPY_DAEMON_RUNNER_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_DAEMON_RUNNER_CONF";

our $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF";

our $KHAOSPY_CONTROLS_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_CONTROLS_CONF";

our $KHAOSPY_BOILERS_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_BOILERS_CONF";

our $KHAOSPY_PI_CONTROLLER_CONF_FULLPATH
    = "$KHAOSPY_CONF_DIR/$KHAOSPY_PI_CONTROLLER_CONF";

#############
our $ONE_WIRE_DAEMON_PORT                = 5001;
### our $PI_CONTROLLER_DAEMON_PUBLISH_PORT = 5002;

our $ALARM_SWITCH_DAEMON_PORT            = 5051;
our $HEATING_CONTROL_DAEMON_PUBLISH_PORT = 5021;

our $PI_CONTROLLER_DAEMON_LISTEN_PORT    = 5061;
our $PI_CONTROLLER_DAEMON_SEND_PORT      = 5062;

our $MAC_SWITCH_DAEMON_PORT              = 5005;
our $PING_SWITCH_DAEMON_PORT             = 5006;

######################
our @EXPORT_OK = qw(
    $ZMQ_CONTEXT

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

    $KHAOSPY_PI_CONTROLLER_CONF
    $KHAOSPY_PI_CONTROLLER_CONF_FULLPATH

    $KHAOSPY_ONE_WIRED_SENDER_SCRIPT
    $KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON
    $KHAOSPY_BOILER_DAEMON_SCRIPT
    $KHAOSPY_PI_CONTROLLER_DAEMON_SCRIPT

    $ONE_WIRE_DAEMON_PORT
    $ALARM_SWITCH_DAEMON_PORT

    $HEATING_CONTROL_DAEMON_PUBLISH_PORT

    $PI_CONTROLLER_DAEMON_LISTEN_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT

    $MAC_SWITCH_DAEMON_PORT
    $PING_SWITCH_DAEMON_PORT

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
            "$KHAOSPY_ONE_WIRE_HEATING_DAEMON",
            # "$KHAOSPY_BOILER_DAEMON_SCRIPT",

        ],
        pitest => [
#            "$KHAOSPY_PI_CONTROLLER_DAEMON_SCRIPT",
        ],

    };
}

sub pi_controller_daemon {
    return {
        pull_from_hosts => [qw/
            pitest
            piold
            piserver
            piloft
            piboiler
        /],
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

# The "name" and "one-wire-address" need to swap places. This config needs to be able to cope with more than just one-wire-attached thermometers. TODO at a very much later stage.
# Doing this would mean the rrd-graph-creator and the heating-control scripts would need to be changed.
sub heating_thermometer_config {
    return {
        '28-0000066ebc74' => {
            name               => 'Alison',
            rrd_group          => 'upstairs',
            upper_temp         => 18.5,
            lower_temp         => 18.0,
            control            => 'alisonrad',
        },
        '28-000006e04e8b' => {
            name               => 'Playhouse-tv',
            rrd_group          => 'sheds',
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
            upper_temp         => 20.0,
            lower_temp         => 19.5,
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
# controls, relays and switches conf.
#####
# Every control has a unique control-name.
# Controls can be turned "on" and "off" or have their "status" queried.
#
#   <type>  can be :
#               orviboS20 ( orvibos20 will also work )
#               pi-gpio-xxx     pi-mcp23017-xxx
#   <host>  is either an hostname or ip-address
#
#   <mac>   is currently only need for Orvibo S20 controls.
#           This might be fixed in the Khaospy::OrviboS20 module, so it just needs the hostname.
#           Configuring orviboS20s is a whole "how-to" in itself, since they will only DHCP,
#           and to get static ips, and hostname via say /etc/hosts takes a bit of configuring of
#           the DHCP server, using nmap to find the orviboS20s etc..
#           The long term plan is to try and drop <mac> for Orvibo S20s.

# above is wrong.

# In the gpio on both pi and i2c-connected-mcp23017 config :
#   a "switch" is an "input" for the gpio
#   a "detect" is an "input" for the gpio. detecting the voltage in part of the circuit.
#   a "relay"  is an "output" for the gpio, controlling usually a relay, but it could control a transistor.
# Hence the config never needs to know the direction the GPIO needs to be set in.
# The direction is implied by the above.

# a "relay" is a control from the automation perspective.

# A "relay" can be wired in 2-way type arangement with a manual-override-switch.
# This is known as a relay-manual.
# So to know if the load is ON the system therefore needs to have a "detect" gpio input.
# In some circuits the detect input is wired in such a way to detect the voltage on the electrical load.
# i.e it measures the result of the 2 inputs to the circuit, the relay and the manual-switch.
# So the GPIO "detect" is the circuit state. This is easy !
#
# In one arangement to simplify wiring and keep costs down, the detect signal is measuring the manual-switch state.
# In this case to get the state of the circuit, the manual-switch-state reported by "detect" needs to be ex-or-ed
# with the gpio-output that is driving the relay.
#
# So for this circuit there is a config option "ex_or_for_state". Which means "ex-or the gpio_relay and gpio_detect" to get the state of the circuit.

# diagrams will make this clearer.


####
# a "switch" only ever has a GPIO input.

# Yes in reality a relay is a switch. To keep things simple here it is being kept that a # relay is something that is under the control of this home-auto system, and a switch is something feeding a logic state into the home-auto system.

####
# invert_state.
#
# The invert_state is necessary because some relays-modules, logic states, switches and wiring-arrangements
# actaully invert what you think the state should be.
# There are relay modules that when you push a 5v signal to them actually switch off.
# There are also different ways of wiring the relay and manual-switch that can invert the logic.
# Wiring a circuit using the normally-open as compared with the normally-closed relay-contacts will also invert state.
# So invert_state deals with this issue.
# If you find a relay, relay-manual or switch is giving you the opposite to what you want just change the invert_state flag.

# pi gpio
# please note the pi-gpio numbers here are the WiringPi GPIO numbers and NOT the BCM CPIO number.
# There are lots of resources on the web that detail what Pi GPIO pins are usable and which ones are double up for use on other things. The gpio pins can change depending on the pi-revision.

# pi i2c mcp23017
# a gpio on one of these needs the following params :
#    i2c_bus  => 0,      # 1 or 0 depending on pi revision.
#    i2c_addr => '0x20', # i2c address of the mcp23017, set by jumper next to the IC on the PCB.
#    portname =>'b',     # a or b ONLY
#    portnum  => 0,      # 0 -> 7
# again the IODIR ( as MCP23017 doc calls it ) is implied by if it is being used to drive a "relay" (out) or being used to read a "switch" (in)



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
        boiler => {
            type => "pi-gpio-relay",
            host => 'piboiler', # FIX THIS it will be piboiler when running.
            gpio_wiringpi => 4, # NOT the BCM CPIO number.
            invert_state => true,
        },

# pi gpio
        a_pi_gpio_relay_manual => {
            type => "pi-gpio-relay-manual",
            host => "pitest",
            ex_or_for_state => false,
            invert_state => false,
            gpio_relay  => 4,
            gpio_detect => 5,
        },

        a_pi_gpio_relay => {
            type => "pi-gpio-relay",
            host => "pitestNOT", # TODO non existant hostname.
            invert_state => false,
            gpio_relay  => 0,
        },

        a_pi_gpio_switch => {
            type => "pi-gpio-switch",
            host => "pitest",
            invert_state => false,
            gpio_switch => 7,
        },

# pi mcp23017

#        a_pi_mcp23017_relay_with_manual => {
#            type => "pi-mcp23017-relay-manual",
#            host => "pitest",
#            ex_or_for_state => false,
#            invert_state => false,
#            gpio_relay => {
#                i2c_bus  => 0,
#		i2c_addr => '0x20',
#		portname =>'b',
#		portnum  => 0,
#            },
#            gpio_detect => {
#                i2c_bus  => 0,
#		i2c_addr => '0x20',
#		portname =>'b',
#		portnum  => 1,
#            },
#
#        },
#
#        a_pi_mcp23017_relay => {
#            type => "pi-mcp23017-relay",
#            host => "pitest",
#            invert_state => false,
#            gpio_relay => {
#                i2c_bus  => 0,
#		i2c_addr => '0x20',
#		portname =>'b',
#		portnum  => 0,
#            },
#        },
#
#        a_pi_mcp23017_switch => {
#            type => "pi-mcp23017-switch",
#            host => "pitest",
#            invert_state => false,
#            gpio_switch => {
#                i2c_bus  => 0,
#		i2c_addr => '0x20',
#		portname =>'b',
#		portnum  => 1,
#            },
#        },

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
