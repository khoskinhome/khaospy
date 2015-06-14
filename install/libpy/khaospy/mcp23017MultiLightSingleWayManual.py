#./install/libpy/khaospy/mcp23017MultiLightSingleWayManual.py
#./install/libpy/test.py

"""
mcp23017MultiLightSingleWayManual is a very long name.

mcp23017 means this device is interfaced with the Raspberry Pi via an MCP23017 chip

MultiLight means that multiple lights can be individually controlled

SingleWayManual means that the manual switch that controls the circuit is a single way. You need to look at the wiring diagram to understand this.

"""

class Device(object):

#    def __init__(self) :
#        return

    def getSwitchMainsState(self) :
        # returns the state of the mains voltage switch.  ( on(true) or off(false) )
        print ("mcp23017MultiLightSingleWayManual.getSwitchMainsState")
        return False

    def getSwitchExtraState(self) :
        # returns the state of the extra low voltage switch. ( on(true) or off(false) )
        print ("mcp23017MultiLightSingleWayManual.getSwitchExtraState")
        return False

    def pollMainsDetector():
        print ("mcp23017MultiLightSingleWayManual.pollMainsDetector")

#    def pollSwitchAndToggle(self) :
#        # polls the state of Li
#        print ("mcp23017MultiLightSingleWayManual.pollSwitchAndToggle")
#        return False

    def areLightsMainlyOn(self) :
        # should this be called "isLightsMainlyOn" ? that sounds wrong to me.
        # returns True or False. If 5 lights out of a possible 9 are "ON" this returns True. If 4 lights out of a possible 9 are "ON" this method returns False.
        print ("mcp23017MultiLightSingleWayManual.areLightsMainlyOn")
        return False

    # if the list-of-lights isn't defined in the following method calls, the default is ALL lights.

    def getLightState ( self, list_of_lights ) :
        # returns an array of 1 or more lights state ( on(true) or off(false) ) . This is a calculated value. ( not the 240v-detector-state ) .
        print ("mcp23017MultiLightSingleWayManual.getLightState %r " % list_of_lights )
        return False

    def setLightOn ( self, list_of_lights ) :
        print ("mcp23017MultiLightSingleWayManual.setLightOn")
        return False

    def setLightOff ( self, list_of_lights ) :
        print ("mcp23017MultiLightSingleWayManual.setLightOff")
        return False

    def setLightToggle ( self, list_of_lights ) :
        print ("mcp23017MultiLightSingleWayManual.setLightToggle")
        return False
        #  ( swaps light from current state. if light is on, this method switches it off )
