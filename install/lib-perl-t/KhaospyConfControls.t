#!perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl/";
# by Karl Kount-Khaos Hoskin. 2015-2016

use Test::More tests => 60;
use Test::Exception;
use Test::Deep;

use Sub::Override;
use Data::Dumper;

sub true  { 1 };
sub false { 0 };

use_ok ( "Khaospy::Conf::Controls", 'get_control_config' );
use_ok ( "Khaospy::Conf::PiHosts" , 'get_pi_host_config' );

use Khaospy::Exception qw(
    KhaospyExcept::ControlDoesnotExist
    KhaospyExcept::ControlsConfig
    KhaospyExcept::ControlsConfigNoType
    KhaospyExcept::ControlsConfigInvalidType
    KhaospyExcept::ControlsConfigUnknownKeys
    KhaospyExcept::ControlsConfigNoKey
    KhaospyExcept::ControlsConfigKeysInvalidValue

    KhaospyExcept::PiHostsNoValidGPIO
    KhaospyExcept::ControlsConfigInvalidGPIO
    KhaospyExcept::ControlsConfigDuplicateGPIO

    KhaospyExcept::PiHostsNoValidI2CBus
    KhaospyExcept::ControlsConfigInvalidI2CBus
    KhaospyExcept::ControlsConfigDuplicateMCP23017GPIO

    KhaospyExcept::ControlsConfigHostUnresovlable
);

# TODO test the loading of a JSON file, for the pi-hosts and controls.

# stop the host resolution from dying.
my $override_is_host_resolvable
    = Sub::Override->new(
        'Khaospy::Conf::Controls::_is_host_resolvable',
        sub {}
);

my $pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
};
my $override_get_pi_hosts_conf
    = Sub::Override->new(
        'Khaospy::Conf::PiHosts::get_pi_hosts_conf',
        sub {
            # simulate the forced setting of the cached
            # $pi_hosts_conf and its validation
            Khaospy::Conf::PiHosts::_set_pi_hosts_conf(
                $pi_hosts_return
            );
            Khaospy::Conf::PiHosts::_validate_pi_hosts_conf();
            return $pi_hosts_return;
        }
);

my $controls_return = {};
my $override_get_controls_conf
    = Sub::Override->new(
        'Khaospy::Conf::Controls::get_controls_conf',
        sub {
            # simulate the forced setting of the cached
            # $controls_conf and its validation
            Khaospy::Conf::Controls::_set_controls_conf(
                $controls_return
            );
            Khaospy::Conf::Controls::_validate_controls_conf();
            return $controls_return;
        }
);

#######################
# Testing Khaospy::Conf::Controls
my $cont_cfg ;

$controls_return = {
    'blahdeblah' => {
    },
};
throws_ok { get_control_config('blahdeblah') }
    qr/KhaospyExcept::ControlsConfigNoType/,
    "dies on no type";

$controls_return = {
    'blahdeblah' => {
        type          => "not-a-valid-type",
    },
};

throws_ok { get_control_config('blahdeblah') }
    qr/KhaospyExcept::ControlsConfigInvalidType/,
    "dies on invalid type";

#############################
# one-wire-thermometer conf :

$controls_return = {
    'therm-loft' => {
        type          => "onewire-thermometer",
        rrd_graph     => true,
        alias         => 'Loft',
        onewire_addr  => '28-021463277cff'  ,
    },
};

ok ( $cont_cfg = get_control_config('therm-loft') , "Can get onewire-thermometer control");
cmp_deeply( $cont_cfg, $controls_return->{'therm-loft'} , "Got the control data" );

$controls_return = {
    'therm-loft' => {
        type          => "onewire-thermometer",
        rrd_graph     => 9, # not a boolean value !
        alias         => 'Loft',
        onewire_addr  => '28-021463277cff'  ,
    },
};
throws_ok { get_control_config('therm-loft') }
    qr/invalid.*?rrd_graph/,
    "dies on invalid boolean for rrd_graph";
throws_ok { get_control_config('therm-loft') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "dies on invalid boolean for rrd_graph";

# remove the optional "alias" field :
$controls_return = {
    'therm-loft' => {
        type          => "onewire-thermometer",
        onewire_addr  => '28-021463277cff'  ,
    },
};
ok ( $cont_cfg = get_control_config('therm-loft') , "Can get control onewire-thermometer. (no alias key)");
cmp_deeply( $cont_cfg, $controls_return->{'therm-loft'} , "Got the control data" );

throws_ok { get_control_config('not-a-control-in-conf') }
    KhaospyExcept::ControlDoesnotExist->new,
    "dies on non-existent control";
##
$controls_return = {
    'therm-loft' => {
        type          => "onewire-thermometer",
        alias         => 'Loft',
        onewire_addr  => '28-021463277cff',
        unknown_key   => "broken!",
    },
};
throws_ok { get_control_config('therm-loft') }
    qr/KhaospyExcept::ControlsConfigUnknownKeys/,
    "dies on an unknown key in onewire-thermometer type";

##
$controls_return = {
    'therm-loft' => {
        type          => "onewire-thermometer",
        alias         => 'Loft',
        onewire_addr  => '28-0243277cff',
    },
};
throws_ok { get_control_config('therm-loft') }
    qr/invalid.*?onewire_addr/,
    "dies on an invalid onewire_addr in onewire-thermometer type";
throws_ok { get_control_config('therm-loft') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "dies on an invalid onewire_addr in onewire-thermometer type";

###########################
# OrviboS20 Conf.

$controls_return = {
        alisonrad       => {
            alias => 'Alison Radiator',
            type  => "orviboS20",
            host  => 'alisonrad',
            mac   => 'AC:CF:23:72:D1:FE',
        },
};
ok ( $cont_cfg = get_control_config('alisonrad') , "Can get control OrviboS20");
cmp_deeply( $cont_cfg, $controls_return->{'alisonrad'} , "Got the control data" );

# remove optional "alias"
$controls_return = {
        alisonrad       => {
            type  => "orviboS20",
            host  => 'alisonrad',
            mac   => 'AC:CF:23:72:D1:FE',
        },
};

ok ( $cont_cfg = get_control_config('alisonrad') , "Can get control OrviboS20 ( no alias key)");
cmp_deeply( $cont_cfg, $controls_return->{'alisonrad'} , "Got the control data" );

$controls_return = {
        alisonrad       => {
            type  => "orviboS20",
            host  => 'alisonrad',
        },
};
throws_ok { get_control_config('alisonrad') }
    qr/KhaospyExcept::ControlsConfigNoKey/,
    "dies on an non-existent-key 'mac' in OrviboS20 type";
throws_ok { get_control_config('alisonrad') }
    qr/doesn't have.*?mac/,
    "dies on an non-existent-key 'mac' in OrviboS20 type";

$controls_return = {
        alisonrad       => {
            type  => "orviboS20",
            host  => 'alisonrad',
            mac   => 'AC:CF:D1:FE',
        },
};
throws_ok { get_control_config('alisonrad') }
    qr/invalid.*?mac/,
    "dies on an invalid 'mac' in OrviboS20 type";
throws_ok { get_control_config('alisonrad') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "dies on an invalid 'mac' in OrviboS20 type";


##########################
# pi-gpio-relay

$controls_return = {
    boiler => {
        alias => 'Boiler Central Heating',
        type  => "pi-gpio-relay",
        host  => 'pitest', # FIX THIS it will be piboiler when running.
        gpio_relay   => 4, # NOT the BCM CPIO number.
        invert_state => true,
    },
};
ok ( $cont_cfg = get_control_config('boiler') , "Can get control pi-gpio-relay ");
cmp_deeply( $cont_cfg, $controls_return->{'boiler'} , "Got the control data" );


# change the valid gpios for the pi-host , and test for failure in the control
$pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 1 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
};
throws_ok { get_control_config('boiler') }
    qr/invalid gpio.*?gpio_relay/,
    "For a pi-gpio-relay control type, dies on an invalid gpio. gpio not defined in pi-hosts.";
throws_ok { get_control_config('boiler') }
    qr/KhaospyExcept::ControlsConfigInvalidGPIO/,
    "For a pi-gpio-relay control type, dies on an invalid gpio. gpio not defined in pi-hosts.";



$pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
};

# test 2 controls using the same gpio on the same pi-host
$controls_return = {
    boiler => {
        alias => 'Boiler Central Heating',
        type  => "pi-gpio-relay",
        host  => 'pitest', # FIX THIS it will be piboiler when running.
        gpio_relay   => 4, # NOT the BCM CPIO number.
        invert_state => true,
    },
    boiler2 => {
        alias => 'Boiler Central Heating 2',
        type  => "pi-gpio-relay",
        host  => 'pitest', # FIX THIS it will be piboiler when running.
        gpio_relay   => 4, # NOT the BCM CPIO number.
        invert_state => true,
    },

};
throws_ok { get_control_config('boiler') }
    qr/boiler.*?same.*?pi_gpio.*boiler/,
    "dies on two controls using same p_gpio on the same pi-host";
throws_ok { get_control_config('boiler') }
    qr/KhaospyExcept::ControlsConfigDuplicateGPIO/,
    "dies on two controls using same p_gpio on the same pi-host";

# test 2 controls using the same gpio on different pi-hosts lives
$pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
    pitest2 => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
};
$controls_return = {
    boiler => {
        alias => 'Boiler Central Heating',
        type  => "pi-gpio-relay",
        host  => 'pitest',
        gpio_relay   => 4,
        invert_state => true,
    },
    boiler2 => {
        alias => 'Boiler Central Heating 2',
        type  => "pi-gpio-relay",
        host  => 'pitest2',
        gpio_relay   => 4,
        invert_state => true,
    },
};
ok ( $cont_cfg = get_control_config('boiler') , "The same pi_gpio can be used on different pi-hosts. ");
cmp_deeply( $cont_cfg, $controls_return->{'boiler'} , "Got the control data" );

# simple validity check on a pi-gpio-relay-manual
$controls_return = {
    a_pi_gpio_relay_manual => {
        type => "pi-gpio-relay-manual",
        host => "pitest",
        ex_or_for_state => false,
        invert_state => false,
        gpio_relay  => 4,
        gpio_detect => 5,
    },
};
ok ( $cont_cfg = get_control_config('a_pi_gpio_relay_manual') , "pi-gpio-relay-manual config is okay  ");
cmp_deeply( $cont_cfg, $controls_return->{'a_pi_gpio_relay_manual'} , "Got the control data" );

# check on a pi-gpio-relay-manual that invert_state must be boolean
$controls_return = {
    a_pi_gpio_relay_manual => {
        type => "pi-gpio-relay-manual",
        host => "pitest",
        ex_or_for_state => false,
        invert_state => 9, # not a valid boolean. 1 or 0 only.
        gpio_relay  => 4,
        gpio_detect => 5,
    },
};
throws_ok { get_control_config('a_pi_gpio_relay_manual') }
    qr/invalid.*?invert_state/,
    "pi-gpio-relay-manual must have a valid boolean for invert_state";
throws_ok { get_control_config('a_pi_gpio_relay_manual') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "pi-gpio-relay-manual must have a valid boolean for invert_state";

# check on a pi-gpio-relay-manual that invert_state must be boolean
$controls_return = {
    a_pi_gpio_relay_manual => {
        type => "pi-gpio-relay-manual",
        host => "pitest",
        ex_or_for_state => 9, # not a valid boolean. 1 or 0 only
        invert_state => false,
        gpio_relay  => 4,
        gpio_detect => 5,
    },
};
throws_ok { get_control_config('a_pi_gpio_relay_manual') }
    qr/invalid.*?ex_or_for_state/,
    "pi-gpio-relay-manual must have a valid boolean for ex_or_for_state";
throws_ok { get_control_config('a_pi_gpio_relay_manual') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "pi-gpio-relay-manual must have a valid boolean for ex_or_for_state";

# check on a pi-gpio-relay-manual can't have both the gpio_relay and gpio_detect set to the same gpio number.
$controls_return = {
    a_pi_gpio_relay_manual => {
        type => "pi-gpio-relay-manual",
        host => "pitest",
        ex_or_for_state => true,
        invert_state => false,
        gpio_relay  => 4, # same gpio as gpio_detect.
        gpio_detect => 4,
    },
};
throws_ok { get_control_config('a_pi_gpio_relay_manual') }
    qr/pi_gpio_relay_manual.*?same.*?pi_gpio.*pi_gpio_relay_manual/,
    "pi_gpio_relay_manual cannot use the same gpio on gpio_relay and gpio_detect";
throws_ok { get_control_config('a_pi_gpio_relay_manual') }
    qr/KhaospyExcept::ControlsConfigDuplicateGPIO/,
    "pi_gpio_relay_manual cannot use the same gpio on gpio_relay and gpio_detect";

# simple validity check on a pi-gpio-relay-manual
$controls_return = {
    a_pi_gpio_switch => {
        type => "pi-gpio-switch",
        host => "pitest",
        invert_state => true,
        gpio_switch => 6,
    },
};
ok ( $cont_cfg = get_control_config('a_pi_gpio_switch') , "pi-gpio-switch config is okay  ");
cmp_deeply( $cont_cfg, $controls_return->{'a_pi_gpio_switch'} , "Got the control data" );

######################
# MCP23017 conf checking.

$pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
};

$controls_return = {
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
};
ok ( $cont_cfg = get_control_config('a_pi_mcp23017_relay') , "pi-mcp23017-relay config is okay  ");
cmp_deeply( $cont_cfg, $controls_return->{'a_pi_mcp23017_relay'} , "Got the control data" );

$controls_return = {
    a_pi_mcp23017_relay => {
        type => "pi-mcp23017-relay",
        host => "pitest",
        invert_state => 9, #  not a boolean 0 or 1
        gpio_relay => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'b',
            portnum  => 0,
        },
    },
};
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/invalid.*?invert_state/,
    "pi-mcp23017-relay must have a valid boolean for invert_state";
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "pi-mcp23017-relay must have a valid boolean for invert_state";

$controls_return = {
    a_pi_mcp23017_relay => {
        type => "pi-mcp23017-relay",
        host => "pitest",
        invert_state => true,
        gpio_relay => {
            i2c_bus  => 0,
            i2c_addr => '0x29', # not a valid i2c_addr for MCP23017
            portname =>'b',
            portnum  => 0,
        },
    },
};
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/invalid.*?i2c_addr/,
    "pi-mcp23017-relay must have a i2c_addr";
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "pi-mcp23017-relay must have a i2c_addr";

####
#  change the i2c_bus in the pi-host conf
$pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 2 ],
        daemons => [],
    },
};

$controls_return = {
    a_pi_mcp23017_relay => {
        type => "pi-mcp23017-relay",
        host => "pitest",
        invert_state => true,
        gpio_relay => {
            i2c_bus  => 0, # not in the pi-host conf.
            i2c_addr => '0x27',
            portname =>'b',
            portnum  => 0,
        },
    },
};
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/invalid.*?i2c_bus.*?gpio_relay/,
    "pi-mcp23017-relay must have a i2c_bus";
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/KhaospyExcept::ControlsConfigInvalidI2CBus/,
    "pi-mcp23017-relay must have a i2c_bus";

####
$pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
};
$controls_return = {
    a_pi_mcp23017_relay => {
        type => "pi-mcp23017-relay",
        host => "pitest",
        invert_state => true,
        gpio_relay => {
            i2c_bus  => 0,
            i2c_addr => '0x27',
            portname => 'c', # not a valid portname
            portnum  => 0,
        },
    },
};
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/invalid.*?portname.*?gpio_relay/,
    "pi-mcp23017-relay must have a portname";
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "pi-mcp23017-relay must have a portname";

###

$controls_return = {
    a_pi_mcp23017_relay => {
        type => "pi-mcp23017-relay",
        host => "pitest",
        invert_state => true,
        gpio_relay => {
            i2c_bus  => 0,
            i2c_addr => '0x27',
            portname => 'A',
            portnum  => 9, # not a valid portnum
        },
    },
};
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/invalid.*?portnum.*?gpio_relay/,
    "pi-mcp23017-relay must have a portnum";
throws_ok { get_control_config('a_pi_mcp23017_relay') }
    qr/KhaospyExcept::ControlsConfigKeysInvalidValue/,
    "pi-mcp23017-relay must have a portnum";

###

$controls_return = {
    a_pi_mcp23017_switch => {
        type => "pi-mcp23017-switch",
        host => "pitest",
        invert_state => false,
        gpio_switch => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'b',
            portnum  => 1,
        },
    },
};
ok ( $cont_cfg = get_control_config('a_pi_mcp23017_switch') , "pi-mcp23017-switch config is okay  ");
cmp_deeply( $cont_cfg, $controls_return->{'a_pi_mcp23017_switch'} , "Got the control data" );

###

$controls_return = {
    a_pi_mcp23017_relay_with_manual => {
        type => "pi-mcp23017-relay-manual",
        host => "pitest",
        ex_or_for_state => false,
        invert_state => false,
        gpio_relay => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'b',
            portnum  => 0,
        },
        gpio_detect => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'b',
            portnum  => 1,
        },

    },
};
ok ( $cont_cfg = get_control_config('a_pi_mcp23017_relay_with_manual') , "pi-mcp23017-relay-manual config is okay  ");
cmp_deeply( $cont_cfg, $controls_return->{'a_pi_mcp23017_relay_with_manual'} , "Got the control data" );


## check both gpios can't be the same.
$controls_return = {
    a_pi_mcp23017_relay_with_manual => {
        type => "pi-mcp23017-relay-manual",
        host => "pitest",
        ex_or_for_state => false,
        invert_state => false,
        gpio_relay => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'B', # same i2c address stuff as the gpio_detect.
            portnum  => 1,
        },
        gpio_detect => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'b',
            portnum  => 1,
        },

    },
};

throws_ok { get_control_config('a_pi_mcp23017_relay_with_manual') }
    qr/a_pi_mcp23017_relay_with_manual.*?same.*?pi_mcp23017.*a_pi_mcp23017_relay_with_manual/,
    "dies on two mcp23017 gpios using same gpio on the same pi-host";
throws_ok { get_control_config('a_pi_mcp23017_relay_with_manual') }
    qr/KhaospyExcept::ControlsConfigDuplicateMCP23017GPIO/,
    "dies on two mcp23017 gpios using same gpio on the same pi-host";


## check mcp23017 gpios can be the same i2c_bus, i2c_addr, portname and portnum on different pi-hosts for 2 different controls.
$pi_hosts_return = {
    pitest => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
    pitest2 => {
        log_level         => 'info',
        valid_gpios       => [ 0..7 ],
        valid_i2c_buses   => [ 0 ],
        daemons => [],
    },
};

$controls_return = {
    a_pi_mcp23017_relay_with_manual => {
        type => "pi-mcp23017-relay-manual",
        host => "pitest",
        ex_or_for_state => false,
        invert_state => false,
        gpio_relay => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'B',
            portnum  => 2,
        },
        gpio_detect => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'b',
            portnum  => 1,
        },

    },

    a_pi_mcp23017_relay_with_manual2 => {
        type => "pi-mcp23017-relay-manual",
        host => "pitest2",
        ex_or_for_state => false,
        invert_state => false,
        gpio_relay => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'B',
            portnum  => 2,
        },
        gpio_detect => {
            i2c_bus  => 0,
            i2c_addr => '0x20',
            portname =>'b',
            portnum  => 1,
        },

    },

};

ok ( $cont_cfg = get_control_config('a_pi_mcp23017_relay_with_manual') , "pi-mcp23017-relay-manual config is okay");
cmp_deeply( $cont_cfg, $controls_return->{'a_pi_mcp23017_relay_with_manual'} , "Got the control data" );


