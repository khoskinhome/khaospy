#./install/libpy/khaospy/mcp23017SingleLightTwoWayManual.py

#from khaospy import oneWirePort, mcp23017DoorWindowSwitch, mcp23017PIRSwitch, mcp23017MultiLightSingleWayManual, kdevice, oneWirePortsCollection, config, mcp23017, daemon, mcp23017BoilerRadiator, factory, exception, Factory, oneWireTemperatureSensor, mcp23017SingleLightTwoWayManual, utils

import khaospy
from khaospy import deviceb
from khaospy import exception

class Device(khaospy.deviceb.Base):
    #iclass Device(object):
    """
    mcp23017SingleLightTwoWayManual is a very long name.

    mcp23017 means this device is interfaced with the Raspberry Pi via an MCP23017 chip

    SingleLight means that a single Lighting circuit is controlled.
    You can have more than one light on the circuit,
    but there is just one two way lighting circuit that controls all the lights.

    TwoWayManual means that the manual switch that controls the circuit is a two way.
    You need to look at the wiring diagram to understand this.

    In the method names "Mains" == 240v Mains ( i.e. not low voltage )
    """

    def getSwitchMainsState(self) :
        # throws an error.
        raise khaospy.exception.Kaboom("mcp23017SingleLightTwoWayManual cannot getSwitchMainsState")

    def getSwitchExtraState(self) :
        # returns the state of the extra low voltage switch. ( on(true) or off(false) )
        print ("mcp23017SingleLightTwoWayManual.getSwitchExtraState")
        return False

    def pollMainsDetector(self):
        print ("mcp23017SingleLightTwoWayManual.pollMainsDetector")
        return True;

#    def pollSwitchAndToggle(self) :
#        # polls the state of Li
#        print ("mcp23017SingleLightTwoWayManual.pollSwitchAndToggle")
#        return False

#    def areLightsMainlyOn(self) :
#        # should this be called "isLightsMainlyOn" ? that sounds wrong to me.
#        # returns True or False. If 5 lights out of a possible 9 are "ON" this returns True. If 4 lights out of a possible 9 are "ON" this method returns False.
#        print ("mcp23017SingleLightTwoWayManual.areLightsMainlyOn")
#        return False

    # if the list-of-lights isn't defined in the following method calls, the default is ALL lights.

    def getLightState ( self ) :
        # returns an the state of the Light ( on(true) or off(false) ) . This is what the 240v-detector detects
        print ("mcp23017SingleLightTwoWayManual.getLightState" )
        return False

    def setLightOn ( self ) :
        print ("mcp23017SingleLightTwoWayManual.setLightOn")
        return False

    def setLightOff ( self ) :
        print ("mcp23017SingleLightTwoWayManual.setLightOff")
        return False

    def setLightToggle ( self ) :
        print ("mcp23017SingleLightTwoWayManual.setLightToggle")
        return False
        #  ( swaps light from current state. if light is on, this method switches it off )




