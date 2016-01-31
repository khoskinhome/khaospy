#!/usr/bin/perl
use strict;
use warnings;

=pod

This fill is just to flesh out the command structure of the requests and responses to the
khaospy-pi-rest-daemon.py

its in perl coz I'm fluent in perl.

It will be implemented in  python

=cut

###########################################################
# getting the device state.
#

# GET on /device/<devicename> # <devicename> can == "all"
my $GET_device_devicename_request = {
    # empty
}

my $on_off     = "on";

my $GET_device_devicename_response = { # for a mcp23017MultiLightSingleWayManual

    mymultilight => {
        homeautoclass => 'mcp23017MultiLightSingleWayManual',
        auto => $on_off,
        main => $on_off,  # calculated value
        multi => {  # where implemented . currently just mcp23017MultiLightSingleWayManual
            1 => $on_off, # calculated value
            2 => $on_off, # calculated value
            3 => $on_off, # calculated value
            # etc....
        },

        relays => {
            1 => $on_off, # actual relay state.
            2 => $on_off,
            3 => $on_off,
            4 => $on_off,
            5 => $on_off,
            6 => $on_off, # highest numbered relay will be the "change-over" that switches from manual to auto control.
            # etc....
        },

        # The type of hv detection that is being done can be worked out by the
        # homeautoclass
        #  mcp23017MultiLightSingleWayManual the hv detector is detecting the switch.
        #  mcp23017SingleLightTwoWayManual the hv detector is detecting the circuit state.
        # See the diagrams to make this clearer.

        inputs_hv => { # the 240v detector . currently we only have 1.
            1 => $on_off, # switch state on the mcp23017MultiLightSingleWayManual
        },

        inputs_lv => { # the low voltage extra input switch. currently there is only 1.
            1 => $on_off,
        },
    }
};

my $GET_device_devicename_response = { # for a mcp23017SingleLightTwoWayManual

    mysingletwowaylight => {
        homeautoclass => 'mcp23017SingleLightTwoWayManual',
        auto => $on_off,
        main => $on_off,

        relays => {
            1 => $on_off,
            2 => $on_off,
        },

        # The type of hv detection that is being done can be worked out by the
        # homeautoclass
        #  mcp23017MultiLightSingleWayManual the hv detector is detecting the switch.
        #  mcp23017SingleLightTwoWayManual the hv detector is detecting the circuit state.
        # See the diagrams to make this clearer.

        inputs_hv => { # the 240v detector . currently we only have 1.
            1 => $on_off,  # circuit state on the mcp23017SingleLightTwoWayManual
        },

        inputs_lv => { # the low voltage extra input switch. currently there is only 1.
            1 => $on_off,
        },
    }
}

my $GET_device_devicename_response = { # for a mcp23017BoilerRadiator
    # the mcp23017BoilerRadiator is oh so similar to the mcp23017MultiLightSingleWayManual
    # except there will never be Multi Lights.
    # might merge this with mcp23017MultiLightSingleWayManual
    myboilerradiator => {
        homeautoclass => 'mcp23017BoilerRadiator',
        auto => $on_off,
        main => $on_off,

        relays => {
            1 => $on_off,
            2 => $on_off,
        },

        # The type of hv detection that is being done can be worked out by the
        # homeautoclass
        #  mcp23017MultiLightSingleWayManual the hv detector is detecting the switch.
        #  mcp23017SingleLightTwoWayManual the hv detector is detecting the circuit state.
        # See the diagrams to make this clearer.

        inputs_hv => { # the 240v detector . currently we only have 1.
            1 => $on_off, # switch state on the mcp23017BoilerRadiator
        },

        inputs_lv => { # the low voltage extra input switch. currently there is only 1.
            1 => $on_off,
        },
    }
};


my $GET_device_devicename_response = { # for a mcp23017AlarmSwitch
    # the mcp23017BoilerRadiator is oh so similar to the mcp23017MultiLightSingleWayManual
    # except there will never be Multi Lights.
    # might merge this with mcp23017MultiLightSingleWayManual
    myalarmswitchdevice => {
        homeautoclass => 'mcp23017AlarmSwitch',
        switch => $on_off,
        tamper => $on_off,
    }
};



########################################################################
## Setting the state

# POST on /device/<devicename>

my $on_off_toggle = 'toggle'; # or 'on' or 'off'

my $POST_device_devicename_request = {

    auto => $on_off_toggle,
    main => $on_off_toggle,
    multi => {  # where implemented . currently just mcp23017MultiLightSingleWayManual
        1 => $on_off_toggle,
        2 => $on_off_toggle,
        3 => $on_off_toggle,
        # etc....
    },
}

# You cannot set state on an alarm switch . That will raise an error.

# You cannot set multi state on things that don't support it. That will raise an error.

####################################################


