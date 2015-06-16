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
    def __init__(self,deviceConfig):
        print "mcp23017MultiLightSingleWayManual __init__"
        super (Device, self).__init__(deviceConfig)

    def addPortsFromConfig(self):
        """
        # here we know the correct type of ports to add.
        """
        #TODO write this

    def getSwitchExtraState(self) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        Returns the state of the extra low voltage switch. ( on(true) or off(false) )
        """
        print ("mcp23017SingleLightTwoWayManual.getSwitchExtraState")
        #TODO write this
        return False


    def getMainsDetector(self):
        """
        Generic method on all Lighting-Power-Control-Module classes.
        This is the state of the 240v detector.
        In this circuit it is also the getCircuitState() ( look at the wiring diagram )
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.pollMainsDetector")
        return True;


    def getCircuitState ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        Returns whether a circuit is on or off.
        In this case that is a single lighting circuit.
        In this class it is the same as the getMainsDetector() ( look at the wiring diagram )
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.getLightState" )
        return False

    def setOn ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setOn")
        return False

    def setOff ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setOff")
        return False

    def setToggle ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        Swaps light from current state. If light is on, this method switches it off
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setToggle")
        return False

    def setAutoOn ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        sets Automation on for this module.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setAutoOn")
        return False

    def setAutoOff ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        sets Automation off for this module.
        This also de-energises all the relays.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setAutoOff")
        return False

    def pollInputsAndToggle(self) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        In this module it only polls the getSwitchExtraState() and if
        the state of this switch has changed, then setToggle() will be called.
        """
        #TODO write this

#    def getSwitchMainsState(self) :
#        # throws an error.
#        raise khaospy.exception.Kaboom("mcp23017SingleLightTwoWayManual cannot getSwitchMainsState")

