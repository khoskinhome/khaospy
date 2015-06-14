#!/usr/bin/python

# ./install/libpy/khaospy/mcp23017MultiLightSingleWayManual.py
import khaospy.mcp23017MultiLightSingleWayManual

# ./install/libpy/khaospy/mcp23017SingleLightTwoWayManual.py
import khaospy.mcp23017SingleLightTwoWayManual

# ./install/libpy/khaospy/utils.py
import khaospy.utils

# ./install/libpy/khaospy/mcp23017Port.py
import khaospy.mcp23017Port

# ./install/libpy/khaospy/mcp23017PortsCollection.py
import khaospy.mcp23017PortsCollection

# ./install/libpy/khaospy/config.py
import khaospy.config



def run():
    mlsw = khaospy.mcp23017MultiLightSingleWayManual.Device()
    mlsw.getSwitchMainsState()

    ## ./install/libpy/khaospy/mcp23017SingleLightTwoWayManual.py
    sltw = khaospy.mcp23017SingleLightTwoWayManual.Device()

    sltw.pollMainsDetector()


    # need to load the config.
    # the config is going to have every automation "device" on all Pis.
    # we only need to instantiate the ones for this Pi. As identified by the IP address.

    # That will require building a "Device" of the correct type.
    # all device's have a "poll" method.
    # this method refeshes the "inputs" that the device has.
    # i.e. a Light circuit will have switch or light states.

#
