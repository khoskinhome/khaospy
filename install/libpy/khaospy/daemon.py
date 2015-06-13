#!/usr/bin/python

# ./install/libpy/khaospy/pi2cMultiLightSingleWayManual.py
import khaospy.pi2cMultiLightSingleWayManual

# ./install/libpy/khaospy/pi2cSingleLightTwoWayManual.py
import khaospy.pi2cSingleLightTwoWayManual

# ./install/libpy/khaospy/utils.py
import khaospy.utils

# ./install/libpy/khaospy/i2cPort.py
import khaospy.i2cPort

# ./install/libpy/khaospy/i2cPortCollection.py
import khaospy.i2cPortCollection

# ./install/libpy/khaospy/config.py
import khaospy.config



def run():
    mlsw = khaospy.pi2cMultiLightSingleWayManual.Device()
    mlsw.getSwitchMainsState()

    ## ./install/libpy/khaospy/pi2cSingleLightTwoWayManual.py
    sltw = khaospy.pi2cSingleLightTwoWayManual.Device()

    sltw.pollMainsDetector()


    # need to load the config.
    # the config is going to have every automation "device" on all Pis.
    # we only need to instantiate the ones for this Pi. As identified by the IP address.

    # That will require building a "Device" of the correct type.
    # all device's have a "poll" method.
    # this method refeshes the "inputs" that the device has.
    # i.e. a Light circuit will have switch or light states.

#
