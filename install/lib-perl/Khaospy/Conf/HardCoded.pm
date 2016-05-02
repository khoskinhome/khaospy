package Khaospy::Conf::HardCoded;
use strict;
use warnings;
# by Karl Kount-Khaos Hoskin. 2015-2016

# for the hard coded live and test confs whilst dev-ing khaospy.
# will probably get deprecated at some point in the future.
# The confs should get generated by a WebUI , but I'm months away from that.

use Exporter qw/import/;

use Khaospy::Constants qw(
    $JSON

    true false

    $CONF_DIR

    $HEATING_DAEMON_CONF
    $CONTROLS_CONF
    $BOILERS_CONF
    $GLOBAL_CONF
    $PI_HOSTS_CONF

    $ONE_WIRE_SENDER_PERL_SCRIPT

    $ONE_WIRED_SENDER_SCRIPT
    $ONE_WIRED_RECEIVER_SCRIPT
    $HEATING_DAEMON_SCRIPT
    $BOILER_DAEMON_SCRIPT
    $PI_CONTROLLER_DAEMON_SCRIPT
    $COMMAND_QUEUE_DAEMON_SCRIPT

    $PI_STATUS_DAEMON_SCRIPT
    $PIBOILER_HOMEEASY_SCHEDULE_DAEMON_SCRIPT

    $OTHER_CONTROLS_DAEMON_SCRIPT

    $ORVIBOS20_CONTROL_TYPE
    $ONEWIRE_THERM_CONTROL_TYPE
    $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE
    $PI_GPIO_RELAY_CONTROL_TYPE
    $PI_GPIO_SWITCH_CONTROL_TYPE
    $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE
    $PI_MCP23017_RELAY_CONTROL_TYPE
    $PI_MCP23017_SWITCH_CONTROL_TYPE
    $MAC_SWITCH_CONTROL_TYPE
    $PING_SWITCH_CONTROL_TYPE

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

    $HEATING_DAEMON_CONF
        => live_heating_thermometer_config(),
    $CONTROLS_CONF
        => live_controls_conf(),
    $BOILERS_CONF
        => live_boilers_conf(),
    $GLOBAL_CONF
        => live_global_conf(),
    $PI_HOSTS_CONF
        => live_pi_host_conf(),

};

my $test_confs = {
    $HEATING_DAEMON_CONF
        => test_heating_thermometer_config(),
    $CONTROLS_CONF
        => test_controls_conf(),
    $BOILERS_CONF
        => test_boilers_conf(),
    $GLOBAL_CONF
        => test_global_conf(),
    $PI_HOSTS_CONF
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

        print "Generating $CONF_DIR/$conf_file\n";

        burp ( "$CONF_DIR/$conf_file",
                $JSON->pretty->encode( $use_conf->{$conf_file} )
        );
    }
}
###############################################################################
# "conf" subs

###############################

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
            upper_temp         => 19.5,
            lower_temp         => 18.5,
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
        '28-041591f5e5ff' => {
            name               => 'Karl',
            rrd_group          => 'downstairs',
            upper_temp         => 17.0,
            lower_temp         => 16.0,
            control            => 'karlrad',
        },
        '28-000006e01389' => {
            name               => 'loft-over-kitchen',
            rrd_group          => 'downstairs',
        },
       '28-011465167eff' => {
            name          => 'Kitchen',
            rrd_group     => 'downstairs',
        },


    };
}
sub test_heating_thermometer_config {
    return {
        %{live_heating_thermometer_config()},

    };
}

sub live_controls_conf {
    ## TODO find a way of using the host name from /etc/hosts to get the ip and mac.
    return {
        'therm-karl' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Karl thermometer',
            onewire_addr  => '28-041591f5e5ff',
        },
        'therm-loft-over-kitchen' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Loft over kitchen',
            onewire_addr  => '28-000006e01389',
        },
        'therm-kitchen' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Kitchen thermometer',
            onewire_addr  => '28-011465167eff'  ,
        },
        'therm-alison-door' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Alison thermometer',
            onewire_addr  => '28-0000066ebc74'  ,
        },
        'therm-playhouse' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Playhouse-tv thermometer.',
            onewire_addr  => '28-000006e04e8b' ,
        },
        'therm-playhouse-door' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Playhouse-9e-door thermometer',
            onewire_addr  => '28-0000066fe99e' ,
        },
        'therm-bathroom' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Bathroom thermometer',
            onewire_addr  => '28-00000670596d'  ,
        },
        'therm-loft' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Loft thermometer',
            onewire_addr  => '28-021463277cff'  ,
        },
        'therm-amelia-door' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Amelia thermometer',
            onewire_addr  => '28-0214632d16ff',
        },
        'therm-upstairs-landing' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Upstairs-Landing thermometer',
            onewire_addr  => '28-021463423bff',
        },
        'therm-outside-front-drive' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'Outside-front-drive thermometer',
            onewire_addr  => '28-000006e04d3c',
        },
        'therm-boiler-ch-in-cold' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'boiler-ch-in-cold thermometer',
            onewire_addr  => '28-000006e00a67',
        },
        'therm-boiler-ch-out-hot' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'boiler-ch-out-hot thermometer',
            onewire_addr  => '28-0114632f89ff',
        },
        'therm-boiler-wh-in-cold' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'boiler-wh-in-cold thermometer',
            onewire_addr  => '28-0414688dbfff',
        },
        'therm-boiler-wh-out-hot' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'boiler-wh-out-hot thermometer',
            onewire_addr  => '28-011465cb13ff',
        },
        'therm-boiler-room' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'boiler-room thermometer',
            onewire_addr  => '28-031463502eff',
        },
        'therm-front-room' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'front-room thermometer',
            onewire_addr  => '28-0214630558ff',
        },
        'therm-front-porch' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'front-porch thermometer',
            onewire_addr  => '28-000006cafb0d',
        },
        'therm-dining-room-near-boiler' => {
            type          => $ONEWIRE_THERM_CONTROL_TYPE,
            alias         => 'dining-room thermometer',
            onewire_addr  => '28-0000066ff2ac',
        },

        alisonrad       => {
            alias => 'Alison Radiator',
            type  => $ORVIBOS20_CONTROL_TYPE,
            host  => 'alisonrad.khaos',
            poll_timeout => 10,
            poll_host => 'piboiler',
            mac   => 'AC:CF:23:72:D1:FE',
        },
        ameliarad       => {
            alias => 'Amelia Radiator',
            type  => $ORVIBOS20_CONTROL_TYPE,
            host  => 'ameliarad.khaos',
            poll_timeout => 10,
            poll_host => 'piboiler',
            mac   => 'AC-CF-23-72-F3-D4',
        },
        karlrad         => {
            alias => 'Karl Radiator',
            type  => $ORVIBOS20_CONTROL_TYPE,
            host  => 'karlrad.khaos',
            poll_timeout => 10,
            poll_host => 'piboiler',
            mac   => 'AC-CF-23-8D-7E-D2',
        },
        dinningroomrad  => {
            alias => 'Dining Room Radiator',
            type  => $ORVIBOS20_CONTROL_TYPE,
            host  => 'diningroomrad.khaos',
            poll_timeout => 10,
            poll_host => 'piboiler',
            mac   => 'AC-CF-23-8D-A4-8E',
        },
        frontroomrad    => {
            alias => 'Front Room Radiator',
            type  => $ORVIBOS20_CONTROL_TYPE,
            host  => 'frontroomrad.khaos',
            poll_timeout => 10,
            poll_host => 'piboiler',
            mac   => 'AC-CF-23-8D-3B-96',
        },

        testsocket      => {
            alias => 'Test Socket',
            type  => $ORVIBOS20_CONTROL_TYPE,
            manual_auto_timeout => 10,
            host  => 'testsocket.khaos',
            poll_timeout => 10,
            poll_host => 'piboiler',
            mac   => 'AC-CF-23-8D-BE-24',
        },

        melissalight  => {
            alias        => 'Melissa Light',
            manual_auto_timeout => 20,
            type         => $ORVIBOS20_CONTROL_TYPE,
            host         => 'melissalight.khaos',
            poll_timeout => 10,
            poll_host    => 'piboiler',
            mac          => 'AC-CF-23-72-28-30',
        },

# pi gpio
        boiler => {
            type => $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE, host => "piboiler",
            ex_or_for_state => false,
            invert_state => true,
            gpio_relay  => 4,
            gpio_detect => 0,
        },

        amelia_pir => { # alarm_01
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 01",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'b', portnum  => 0,
            },
        },
        amelia_window => { # alarm 02
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 02",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'b', portnum  => 1,
            },
        },
        alison_pir => { # alarm 03
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 03",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'b', portnum  => 2,
            },
        },
        alison_window => { # alarm 04
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 04",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'b', portnum  => 3,
            },
        },
        dining_room_pir => { # alarm 05
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 05",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'b', portnum  => 4,
            },
        },
        dining_room_window => { # alarm 06
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 06",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'b', portnum  => 5,
            },
        },
        front_room_pir => { # alarm 07
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 07",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'b', portnum  => 6,
            },
        },
        front_room_window => { # alarm 08
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 08",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'b', portnum  => 7,
            },
        },
        front_outside_door => { # alarm_09
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 09",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'a', portnum  => 7,
            },
        },
        front_porch_pir => { # alarm 10
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 10",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'a', portnum  => 6,
            },
        },
        inner_front_door => { # alarm 11
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 11",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'a', portnum  => 5,
            },
        },
        inner_front_door_deadlock => { # alarm 12
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 12",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'a', portnum  => 4,
            },
        },
        front_room_door => { # alarm 13
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 13",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'a', portnum  => 3,
            },
        },
        alarm_14 => { # alarm 14
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 14",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'a', portnum  => 2,
            },
        },
        alarm_15 => { # alarm 15
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 15",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'a', portnum  => 1,
            },
        },
        alarm_16 => { # alarm 16
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 16",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x20', portname =>'a', portnum  => 0,
            },
        },

        alarm_17 => { # alarm_17
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 17",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'b', portnum  => 0,
            },
        },
        alarm_18 => { # alarm 18
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 18",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'b', portnum  => 1,
            },
        },
        alarm_19 => { # alarm 19
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 19",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'b', portnum  => 2,
            },
        },
        alarm_20 => { # alarm 20
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 20",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'b', portnum  => 3,
            },
        },
        alarm_21 => { # alarm 21
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 21",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'b', portnum  => 4,
            },
        },
        alarm_22 => { # alarm 22
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 22",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'b', portnum  => 5,
            },
        },
        alarm_23 => { # alarm 23
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 23",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'b', portnum  => 6,
            },
        },
        alarm_24 => { # alarm 24
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 24",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'b', portnum  => 7,
            },
        },
        alarm_25 => { # alarm_25
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 25",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'a', portnum  => 7,
            },
        },
        alarm_26 => { # alarm 26
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 26",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'a', portnum  => 6,
            },
        },
        alarm_27 => { # alarm 27
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 27",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'a', portnum  => 5,
            },
        },
        alarm_28 => { # alarm 28
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm 28",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'a', portnum  => 4,
            },
        },
        alarm_tamp_1 => { # alarm tamp-1
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm tamper 1",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'a', portnum  => 3,
            },
        },
        alarm_tamp_2 => { # alarm tamp-2
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm tamper 2",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'a', portnum  => 2,
            },
        },
        alarm_tamp_3 => { # alarm tamp-3
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm tamper 3",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'a', portnum  => 1,
            },
        },
        alarm_tamp_4 => { # alarm tamp-4
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE  , host => "piserver", invert_state => false,
            alias => "alarm tamper 4",
            gpio_switch => {
                i2c_bus  => 1 , i2c_addr => '0x21', portname =>'a', portnum  => 0,
            },
        },
    };
}

sub test_controls_conf {
    ## TODO find a way of using the host name from /etc/hosts to get the ip and mac.
    return {
        %{live_controls_conf()},

## pi gpio
        pigpio_relay => {
            alias => 'pi gpio relay',
            type  => $PI_GPIO_RELAY_CONTROL_TYPE,
            host  => 'pitest',
            invert_state => true,
            gpio_relay   => 1,
        },

#        pigpio_switch => {
#            type => $PI_GPIO_SWITCH_CONTROL_TYPE,
#            host => "pitest",
#            invert_state => false,
#            gpio_switch => 7,
#        },

        pigpio_relay_manual => {
            type => $PI_GPIO_RELAY_MANUAL_CONTROL_TYPE,
            host => "pitest",
            ex_or_for_state => false,
            invert_state => false,
            manual_auto_timeout => 20,
            gpio_relay  => 4,
            gpio_detect => 0,
        },

# pi mcp23017
#        mcp_relay_man_0 => {
#            type => $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE,
#            host => "pitest",
#            ex_or_for_state => true,
#            invert_state => false,
#            gpio_relay => {
#                i2c_bus  => 0,
#		i2c_addr => '0x27',
#		portname =>'b',
#		portnum  => 3,
#            },
#            gpio_detect => {
#                i2c_bus  => 0,
#		i2c_addr => '0x27',
#		portname =>'b',
#		portnum  => 0,
#            },
#        },
#
#        mcp_relay_0 => {
#            type => $PI_MCP23017_RELAY_CONTROL_TYPE,
#            host => "pitest",
#            invert_state => false,
#            gpio_relay => {
#                i2c_bus  => 0,
#		i2c_addr => '0x27',
#		portname =>'b',
#		portnum  => 1,
#            },
#        },
#
#        mcp_switch_0 => {
#            type => $PI_MCP23017_SWITCH_CONTROL_TYPE,
#            host => "pitest",
#            invert_state => false,
#            gpio_switch => {
#                i2c_bus  => 0,
#		i2c_addr => '0x27',
#		portname =>'b',
#		portnum  => 2,
#            },
#        },

        mcp_relay_man_1 => {
            type => $PI_MCP23017_RELAY_MANUAL_CONTROL_TYPE,
            host => "pitest",
            ex_or_for_state => true,
            invert_state => false,
            manual_auto_timeout => 20,
            gpio_relay => {
                i2c_bus  => 1,
		i2c_addr => '0x27',
		portname =>'b',
		portnum  => 3,
            },
            gpio_detect => {
                i2c_bus  => 1,
		i2c_addr => '0x27',
		portname =>'b',
		portnum  => 0,
            },
        },

        mcp_relay_1 => {
            type => $PI_MCP23017_RELAY_CONTROL_TYPE,
            host => "pitest",
            invert_state => false,
            gpio_relay => {
                i2c_bus  => 1,
		i2c_addr => '0x27',
		portname =>'b',
		portnum  => 1,
            },
        },

        mcp_switch_1 => {
            type => $PI_MCP23017_SWITCH_CONTROL_TYPE,
            host => "pitest",
            invert_state => false,
            gpio_switch => {
                i2c_bus  => 1,
		i2c_addr => '0x27',
		portname =>'b',
		portnum  => 2,
            },
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

sub live_boilers_conf {
    return {
        # frontroomrad is being using as the boiler control. This needs fixing.
        boiler => {
            on_delay_secs => 120,
            controls => [qw/
                alisonrad
                frontroomrad
                ameliarad
                dinningroomrad
                karlrad
            /],

        },
    };
}

sub test_boilers_conf {
    return live_boilers_conf();
#    return {
#        # frontroomrad is being using as the boiler control. This needs fixing.
#        karlrad => {
#            on_delay_secs => 120, # TODO this should really be 120
#            controls => [qw/
#                mcp_relay_man
#                mcp_relay
#            /],
#
#        },
#    };
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

# The valid_gpio key is COMPULSORY if the specific Pi-host has controls configured that use GPIO. This is used in Khaospy::Conf::Controls for validation.

# The valid_i2c_bus key is COMPULSORY if the specific Pi-host has controls configured that uses i2c_bus (MCP23017 chips). This is used in Khaospy::Conf::Controls for validation.

sub live_pi_host_conf {
    return {
        piserver => {
            log_level         => 'info',
            valid_gpios       => [ 0..7 ],
            valid_i2c_buses   => [ 0, 1 ],
            daemons => [
                { script  => $PI_STATUS_DAEMON_SCRIPT,  options => { }, },
                { script  =>$ONE_WIRED_SENDER_SCRIPT,
                  options => { '--stdout_freq' => '890' },
                },
                { script  => $ONE_WIRE_SENDER_PERL_SCRIPT,  options => { }, },
                {
                    script  => $ONE_WIRED_RECEIVER_SCRIPT,
                    options => { '--host' => "pioldwifi" },
                },
                {
                    script  => $ONE_WIRED_RECEIVER_SCRIPT,
                    options => { '--host' => "piserver" },
                },
                {
                    script  => $ONE_WIRED_RECEIVER_SCRIPT,
                    options => { '--host' => "piloft" },
                },
                {
                    script  => $ONE_WIRED_RECEIVER_SCRIPT,
                    options => { '--host' => "piboiler" },
                },
                { script  => $PI_CONTROLLER_DAEMON_SCRIPT, options => { }, },
                { script  => $COMMAND_QUEUE_DAEMON_SCRIPT, options => { }, },
            ],
        },
        piloft => {
            log_level         => 'info',
            valid_gpios       => [ 0..7 ],
            valid_i2c_buses   => [ 1 ],
            daemons => [
                {
                    script  =>$ONE_WIRED_SENDER_SCRIPT,
                    options => { '--stdout_freq' => '890' },
                },
                { script  => $ONE_WIRE_SENDER_PERL_SCRIPT,  options => { }, },
                {
                    script  =>"/opt/khaospy/bin/khaospy-amelia-hackit-daemon.pl",
                    options => { },
                },
            ],
        },
        piold => {
            log_level         => 'info',
            valid_gpios       => [ 0..7 ],
            valid_i2c_buses   => [ 0 ],
            daemons => [
                {
                    script  =>$ONE_WIRED_SENDER_SCRIPT,
                    options => { '--stdout_freq' => '890' },
                },
                { script  => $ONE_WIRE_SENDER_PERL_SCRIPT,  options => { }, },
            ],
        },
        piboiler => {
            log_level         => 'info',
            valid_gpios       => [ 0..7 ],
            valid_i2c_buses   => [ 1 ],
            daemons => [
                { script  =>$ONE_WIRED_SENDER_SCRIPT,
                  options => { '--stdout_freq' => '890' },
                },
                { script  => $ONE_WIRE_SENDER_PERL_SCRIPT,  options => { }, },
                { script  => $HEATING_DAEMON_SCRIPT,        options => { }, },
                { script  => $BOILER_DAEMON_SCRIPT,         options => { }, },
                { script  => $PI_CONTROLLER_DAEMON_SCRIPT,  options => { }, },
                { script  => $COMMAND_QUEUE_DAEMON_SCRIPT,  options => { }, },
                { script  => $OTHER_CONTROLS_DAEMON_SCRIPT, options => { }, },
                { script  => $PIBOILER_HOMEEASY_SCHEDULE_DAEMON_SCRIPT, options =>{}, },
            ],
        },
    };
}

sub test_pi_host_conf {
    return {
        %{live_pi_host_conf()},
        pitest => {
            log_level         => 'info',
            valid_gpios       => [ 0..7 ],
            valid_i2c_buses   => [ 0, 1 ], # could do an i2cdetect too.
            daemons => [
                {
                    script  => $PI_CONTROLLER_DAEMON_SCRIPT,
                    options => {
## TODO implement --log_level cli-opt on daemon-scripts.
##                      '--log_level' => "debug", # over-ride per host setting.
                    },
                },
                {
                    script  => $OTHER_CONTROLS_DAEMON_SCRIPT,
                    options => {
## TODO implement --log_level cli-opt on daemon-scripts.
##                      '--log_level' => "debug", # over-ride per host setting.
                    },
                },

                {
                    script  => $COMMAND_QUEUE_DAEMON_SCRIPT,
                    options => {
## TODO implement --log_level cli-opt on daemon-scripts.
##                      '--log_level' => "debug", # over-ride per host setting.
                    },
                },

            ],
        },
    };
}

1;
