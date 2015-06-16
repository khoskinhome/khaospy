#./install/libpy/khaospy/mcp23017MultiLightSingleWayManual.py

"""
mcp23017MultiLightSingleWayManual is a very long name.

mcp23017 means this device is interfaced with the Raspberry Pi via an MCP23017 chip

MultiLight means that multiple lights can be individually controlled

SingleWayManual means that the manual switch that controls the circuit is a single way. You need to look at the wiring diagram to understand this.

"""
import khaospy
from khaospy import deviceb
from khaospy import exception

class Device(khaospy.deviceb.Base):
    #class Device(object):

    def __init__(self,deviceConfig):
        print "mcp23017MultiLightSingleWayManual __init__"
        super (Device, self).__init__(deviceConfig)

    def addPortsFromConfig(self):
        """
        Call the addPort on the correct type of portsCollection

        The multiLights in the array get flattened out to having a PortName of :

            "DeviceName.Light[0]"
        
        """
        #TODO write this

    def getSwitchExtraState(self) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        Returns the state of the extra low voltage switch. ( on(true) or off(false) )
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.getSwitchExtraState")
        return False

    def getMainsDetector(self):
        """
        Generic method on all Lighting-Power-Control-Module classes.
        This is the state of the 240v detector.
        In this circuit this is also the state of the mains switch ( look at the wiring diagram )
        This method is a synonym for getSwitchMainsState(self) 
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.getMainsDetector")
        return True;


    def getCircuitState ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        Returns whether a circuit is on or off.
        That is in fact a lie.
        This returns a calculated value of how many lights are on.
        This method is a synonym for areLightsMainlyOn(self)
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.getCircuitState" )
        return False

    def setOn ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        This will set all of the 1 or more Lighting circuits on.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setOn")
        return False

    def setOff ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        This will set all of the 1 or more Lighting circuits off.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setOff")
        return False

    def setToggle ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        Swaps light from current state. If light is on, this method switches it off
        This will toggle all of the 1 or more Lighting circuits to the opposite state.
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

    ##########################################################
    # methods specific to MultiLight 
    ##########################################################

    def getSwitchMainsState(self) :
        """
        Of the two light circuit arrangements only MultiLightsSingleWayManual
        can detect the state of the Old-Manual-Mains-Wall-Switch.

        Returns the state of the mains voltage switch.  ( on(true) or off(false) )
        """
        #TODO write this
        print ("mcp23017MultiLightSingleWayManual.getSwitchMainsState")
        return False

    def areLightsMainlyOn(self) :
        """
        Only the MultiLightsSingleWayManual type of wiring needs to do a calculation
        on whether more or less of the individual lamps are on.
        ( this is used when "toggling" all lights.)

        The return value is calculated using the relay states and the getMainsDetector state.

        If the majority (or all) of the lights are "ON" this method returns True,
        otherwise it returns False.
        """
        #TODO write this
        print ("mcp23017MultiLightSingleWayManual.areLightsMainlyOn")
        return False

    def getCircuitStateArray ( self ) :
        """
        returns an array with the calculated state of all the lights in the multiple circuits.
        This is actually the state that the relay is in, and if necessary the getMainsDetector state is used. 

        """
        #TODO write this

    def setOnArray ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        This will set all of the 1 or more Lighting circuits on.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setOn")
        return False

    def setOffArray ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        This will set all of the 1 or more Lighting circuits off.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setOff")
        return False

    def setToggleArray ( self ) :
        """
        Generic method on all Lighting-Power-Control-Module classes.
        Swaps light from current state. If light is on, this method switches it off
        This will toggle all of the 1 or more Lighting circuits to the opposite state.
        """
        #TODO write this
        print ("mcp23017SingleLightTwoWayManual.setToggle")
        return False

