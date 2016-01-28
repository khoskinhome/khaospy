package Khaospy::Conf::HardCoded;
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

# by Karl Kount-Khaos Hoskin. 2015-2016

# for the hard coded live and test confs whilst dev-ing khaospy.
# will probably get deprecated at some point in the future.
# The confs should get generated by a WebUI , but I'm months away from that.

use Exporter qw/import/;

use Khaospy::Constants qw(
    $JSON

    true false

    $KHAOSPY_CONF_DIR

    $KHAOSPY_DAEMON_RUNNER_CONF
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF
    $KHAOSPY_CONTROLS_CONF
    $KHAOSPY_BOILERS_CONF
    $KHAOSPY_GLOBAL_CONF
    $KHAOSPY_PI_HOSTS_CONF

    $KHAOSPY_ONE_WIRED_SENDER_SCRIPT
    $KHAOSPY_ONE_WIRED_RECEIVER_SCRIPT
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON
    $KHAOSPY_BOILER_DAEMON_SCRIPT
    $KHAOSPY_PI_CONTROLLER_DAEMON_SCRIPT
    $KHAOSPY_PI_CONTROLLER_QUEUE_DAEMON_SCRIPT

);

use Khaospy::Utils qw/burp/;

sub CONF_LIVE {"live"};
sub CONF_TEST {"test"};

our @EXPORT_OK = qw(
    CONF_LIVE
    CONF_TEST
    write_out_conf
);


my $live_confs = {
    $KHAOSPY_DAEMON_RUNNER_CONF
        => live_daemon_runner_conf(),
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF
        => live_heating_thermometer_config(),
    $KHAOSPY_CONTROLS_CONF
        => live_controls_conf(),
    $KHAOSPY_BOILERS_CONF
        => live_boilers_conf(),
    $KHAOSPY_GLOBAL_CONF
        => live_global_conf(),
    $KHAOSPY_PI_HOSTS_CONF
        => live_pi_host_conf(),
};

my $test_confs = {
    $KHAOSPY_DAEMON_RUNNER_CONF
        => test_daemon_runner_conf(),
    $KHAOSPY_ONE_WIRE_HEATING_DAEMON_CONF
        => test_heating_thermometer_config(),
    $KHAOSPY_CONTROLS_CONF
        => test_controls_conf(),
    $KHAOSPY_BOILERS_CONF
        => test_boilers_conf(),
    $KHAOSPY_GLOBAL_CONF
        => test_global_conf(),
    $KHAOSPY_PI_HOSTS_CONF
        => test_pi_host_conf(),
};

sub write_out_conf {

    my ($live_or_test) = @_;

    my $use_conf;

    if ($live_or_test eq CONF_LIVE ) {
        $use_conf = $live_confs;
    } elsif ($live_or_test eq CONF_TEST ) {
        $use_conf = $test_confs;
    } else {
        die "didn't define live or test correctly to write out the hardcoded conf\n";

    }

    for my $conf_file ( keys %$use_conf ) {

        print "Generating $KHAOSPY_CONF_DIR/$conf_file\n";

        burp ( "$KHAOSPY_CONF_DIR/$conf_file",
                $JSON->pretty->encode( $use_conf->{$conf_file} )
        );
    }
}
###############################################################################
# "conf" subs

###############################
# daemon_runner_conf keys
#
# The primary key is the hostname on where the script should run.
#
# this points to an array of script names to be run by /usr/bin/daemon ( with CLI params )
#
# TODO to be deprecated, and migrated to the pi_host conf
sub live_daemon_runner_conf {
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

# TODO to be deprecated, and migrated to the pi_host conf
sub test_daemon_runner_conf {
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
sub live_heating_thermometer_config {
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
sub test_heating_thermometer_config {
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
# controls, relays, switches, sensors conf.
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



sub live_controls_conf {
    ## TODO find a way of using the host name from /etc/hosts to get the ip and mac.
    return {

        'therm-alison-door' => {
            type          => "onewire-thermometer",
            alias         => 'Alison',
            onewire_addr  => '28-0000066ebc74'  ,
        },
        'therm-playhouse' => {
            type          => "onewire-thermometer",
            alias         => 'Playhouse-tv',
            onewire_addr  => '28-000006e04e8b' ,
        },
        'therm-playhouse-door' => {
            type          => "onewire-thermometer",
            alias         => 'Playhouse-9e-door',
            onewire_addr  => '28-0000066fe99e' ,
        },
        'therm-bathroom' => {
            type          => "onewire-thermometer",
            alias         => 'Bathroom',
            onewire_addr  => '28-00000670596d'  ,
        },
        'therm-loft' => {
            type          => "onewire-thermometer",
            alias         => 'Loft',
            onewire_addr  => '28-021463277cff'  ,
        },
        'therm-amelia-door' => {
            type          => "onewire-thermometer",
            alias         => 'Amelia',
            onewire_addr  => '28-0214632d16ff',
        },
        'therm-upstairs-landing' => {
            type          => "onewire-thermometer",
            alias         => 'Upstairs-Landing',
            onewire_addr  => '28-021463423bff',
        },
        'therm-outside-front-drive' => {
            type          => "onewire-thermometer",
            alias         => 'Outside-front-drive',
            onewire_addr  => '28-000006e04d3c',
        },
        'therm-boiler-ch-in-cold' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-ch-in-cold',
            onewire_addr  => '28-000006e00a67',
        },
        'therm-boiler-ch-out-hot' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-ch-out-hot',
            onewire_addr  => '28-0114632f89ff',
        },
        'therm-boiler-wh-in-cold' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-wh-in-cold',
            onewire_addr  => '28-0414688dbfff',
        },
        'therm-boiler-wh-out-hot' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-wh-out-hot',
            onewire_addr  => '28-011465cb13ff',
        },
        'therm-boiler-room' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-room',
            onewire_addr  => '28-031463502eff',
        },
        'therm-front-room' => {
            type          => "onewire-thermometer",
            alias         => 'front-room',
            onewire_addr  => '28-0214630558ff',
        },
        'therm-front-porch' => {
            type          => "onewire-thermometer",
            alias         => 'front-porch',
            onewire_addr  => '28-000006cafb0d',
        },
        'therm-dining-room-near-boiler' => {
            type          => "onewire-thermometer",
            alias         => 'dining-room',
            onewire_addr  => '28-0000066ff2ac',
        },

        alisonrad       => {
            alias => 'Alison Radiator',
            type  => "orviboS20",
            host  => 'alisonrad',
            mac   => 'AC:CF:23:72:D1:FE',
        },
        ameliarad       => {
            alias => 'Amelia Radiator',
            type  => "orviboS20",
            host  => 'ameliarad',
            mac   => 'AC-CF-23-72-F3-D4',
        },
        karlrad         => {
            alias => 'Karl Radiator',
            type  => "orviboS20",
            host  => 'karlrad',
            mac   => 'AC-CF-23-8D-7E-D2',
        },
        dinningroomrad  => {
            alias => 'Dining Room Radiator',
            type  => "orviboS20",
            host  => 'dinningroomrad',
            mac   => 'AC-CF-23-8D-A4-8E',
        },
        frontroomrad    => {
            alias => 'Front Room Radiator',
            type  => "orviboS20",
            host  => 'frontroomrad',
            mac   => 'AC-CF-23-8D-3B-96',
        },


#        broken_frontroomrad    => {
#            alias => 'Front Room Radiator',
#            type  => "orviboS20",
#            host  => 'frontroomrad',
#            mac   => 'ACCF-23-8D-3B-96',
#            extra => "bah",
#
#        },

        boiler => {
            alias => 'Boiler Central Heating',
            type  => "pi-gpio-relay",
            host  => 'pitest', # FIX THIS it will be piboiler when running.
            gpio_relay   => 4, # NOT the BCM CPIO number.
            invert_state => true,
        },

# pi gpio
        a_pi_gpio_relay_manual => {
            type => "pi-gpio-relay-manual",
            host => "pitest",
            ex_or_for_state => false,
            invert_state => false,
            gpio_relay  => 3,
            gpio_detect => 5,
        },

        a_pi_gpio_relay => {
            type => "pi-gpio-relay",
            host => "pitest",
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
        a_pi_mcp23017_relay => {
            type => "pi-mcp23017-relay",
            host => "pitest",
            invert_state => false,
            gpio_relay => {
                i2c_bus  => 0,
		i2c_addr => '0x20',
		portname =>'b',
		portnum  => 0,
            },
        },

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

sub test_controls_conf {
    ## TODO find a way of using the host name from /etc/hosts to get the ip and mac.
    return {

        'therm-alison-door' => {
            type          => "onewire-thermometer",
            alias         => 'Alison',
            onewire_addr  => '28-0000066ebc74'  ,
        },
        'therm-playhouse' => {
            type          => "onewire-thermometer",
            alias         => 'Playhouse-tv',
            onewire_addr  => '28-000006e04e8b' ,
        },
        'therm-playhouse-door' => {
            type          => "onewire-thermometer",
            alias         => 'Playhouse-9e-door',
            onewire_addr  => '28-0000066fe99e' ,
        },
        'therm-bathroom' => {
            type          => "onewire-thermometer",
            alias         => 'Bathroom',
            onewire_addr  => '28-00000670596d'  ,
        },
        'therm-loft' => {
            type          => "onewire-thermometer",
            alias         => 'Loft',
            onewire_addr  => '28-021463277cff'  ,
        },
        'therm-amelia-door' => {
            type          => "onewire-thermometer",
            alias         => 'Amelia',
            onewire_addr  => '28-0214632d16ff',
        },
        'therm-upstairs-landing' => {
            type          => "onewire-thermometer",
            alias         => 'Upstairs-Landing',
            onewire_addr  => '28-021463423bff',
        },
        'therm-outside-front-drive' => {
            type          => "onewire-thermometer",
            alias         => 'Outside-front-drive',
            onewire_addr  => '28-000006e04d3c',
        },
        'therm-boiler-ch-in-cold' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-ch-in-cold',
            onewire_addr  => '28-000006e00a67',
        },
        'therm-boiler-ch-out-hot' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-ch-out-hot',
            onewire_addr  => '28-0114632f89ff',
        },
        'therm-boiler-wh-in-cold' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-wh-in-cold',
            onewire_addr  => '28-0414688dbfff',
        },
        'therm-boiler-wh-out-hot' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-wh-out-hot',
            onewire_addr  => '28-011465cb13ff',
        },
        'therm-boiler-room' => {
            type          => "onewire-thermometer",
            alias         => 'boiler-room',
            onewire_addr  => '28-031463502eff',
        },
        'therm-front-room' => {
            type          => "onewire-thermometer",
            alias         => 'front-room',
            onewire_addr  => '28-0214630558ff',
        },
        'therm-front-porch' => {
            type          => "onewire-thermometer",
            alias         => 'front-porch',
            onewire_addr  => '28-000006cafb0d',
        },
        'therm-dining-room-near-boiler' => {
            type          => "onewire-thermometer",
            alias         => 'dining-room',
            onewire_addr  => '28-0000066ff2ac',
            extra_key_err => "yuck !",
        },

        alisonrad       => {
            alias => 'Alison Radiator',
            type  => "orviboS20",
            host  => 'alisonrad',
            mac   => 'AC:CF:23:72:D1:FE',
        },
        ameliarad       => {
            alias => 'Amelia Radiator',
            type  => "orviboS20",
            host  => 'ameliarad',
            mac   => 'AC-CF-23-72-F3-D4',
        },
        karlrad         => {
            alias => 'Karl Radiator',
            type  => "orviboS20",
            host  => 'karlrad',
            mac   => 'AC-CF-23-8D-7E-D2',
        },
        dinningroomrad  => {
            alias => 'Dining Room Radiator',
            type  => "orviboS20",
            host  => 'dinningroomrad',
            mac   => 'AC-CF-23-8D-A4-8E',
        },
        frontroomrad    => {
            alias => 'Front Room Radiator',
            type  => "orviboS20",
            host  => 'frontroomrad',
            mac   => 'AC-CF-23-8D-3B-96',
        },


        broken_frontroomrad    => {
            alias => 'Front Room Radiator',
            type  => "orviboS20",
            host  => 'frontroomrad',
            mac   => 'ACCF-23-8D-3B-96',
            extra => "bah",

        },

        boiler => {
            alias => 'Boiler Central Heating',
            type  => "pi-gpio-relay",
            host  => 'pitest', # FIX THIS it will be piboiler when running.
            gpio_relay   => 4, # NOT the BCM CPIO number.
#            invert_state => true,  ERROR ! 
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

        duplicate_gpio_a_pi_gpio_relay => {
            type => "pi-gpio-relay",
            host => "pitestNOT", # TODO non existant hostname.
            invert_state => false,
            gpio_relay  => 0,
        },

        a_pi_gpio_switch => {
            type => "pi-gpio-switch",
            host => "pitest",
            invert_state => false,
            gpio_switch => 9, # ERROR !
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

sub live_boilers_conf {
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

sub test_boilers_conf {
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

# TODO to be deprecated.
sub live_global_conf {
    return {
        log_level => 'debug',
    };
}

# TODO to be deprecated.
sub test_global_conf {
    return {
        log_level => 'debug',
    };
}


#####################################################
# Pi Host conf.
# the daemon-runner conf will get migrated to this pi_host conf.
# The daemons will also not have CLI switches. These will be read from this conf.
#
# the log_level will get migrated to the pi_host conf

# The valid_gpio key is COMPULSORY if the specific Pi-host has controls configured that use GPIO. This is used in Khaospy::Conf::Controls for validation.

# The valid_i2c_bus key is COMPULSORY if the specific Pi-host has controls configured that uses i2c_bus (MCP23017 chips). This is used in Khaospy::Conf::Controls for validation.
sub live_pi_host_conf {
    return {
        pitest => {
            log_level         => 'debug',
            valid_gpios       => [ 0..7 ],
            valid_i2c_buses   => [ 0 ],
            daemons => [
                $KHAOSPY_PI_CONTROLLER_DAEMON_SCRIPT => {
                    option => "blah",
                    log_level => "debug", # over-ride per host setting.
                },

            ],
        },
    };
}

sub test_pi_host_conf {
    return {
        pitest => {
            log_level         => 'debug',
            valid_gpios       => [ 0..7 ],
            valid_i2c_buses   => [ 0 ],
            daemons => [
                $KHAOSPY_PI_CONTROLLER_DAEMON_SCRIPT => {
                    option => "blah",
                    log_level => "debug", # over-ride per host setting.
                },

            ],
        },
    };
}

1;
