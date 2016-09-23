
import khaospy
from khaospy import exception

"""
MCP23017 is a port expander chip :
    http://www.microchip.com/wwwproducts/Devices.aspx?product=MCP23017
    http://www.raspberrypi-spy.co.uk/2013/07/how-to-use-a-mcp23017-i2c-port-expander-with-the-raspberry-pi-part-2/

This file and its classes handle I/O from the Raspberry Pi to this chip.

The rationale behind this class is that the Devices ( by which I mean home-automation devices ) get and set the port objects in the singleton collection of ports class here (using classmethods and attributes ).

Only once the pollAllOutputs() or pollAllInputs() calls are made are the commands sent from the Raspberry Pi via its i2c interface to the MCP23017 chips.

It is done this way because calls on the i2c bus to an MCP23017 aren't slow, but they're not that quick either. The do "bind" up the pi. 

One MCP23017 chip has 16 lines of I/O. These 16 lines will be spread over several home automation devices.

Now to issue out commands on the i2c bus to poll just one home automation device using a couple of lines of I/O on the MCP23017 is wasteful, and will make polling slower.

So aggregating all the MCP23017 ports here, and just doing one call to pollAllInputs() and pollAllOutputs() once per loop of the main control daemon is much more efficient.

"""

class port(object):
    # a single port on a MCP23017 chip
    """
    A single GPIO port on an MCP23017.

    has
      "i2cbus" : 0,
      "i2cAddress" : "0x27",

      "enabled" : 0,
      "inORout" : 1,
      "current_state" : 1,
      "portnum" : 2,
      "port" : "a"

    """
    def __init__(self,portConfig):
        print ( "mcp23017 port __init__() called for %s " % portConfig['PortName'] )
        self.portConfig = portConfig
        #TODO write this




##############################################################
# should I use smbus or quick2wire ?  dunno.

class collection(object):
    """
    Has all the mcp23017 ports, on all the mcp23017 chips. ( using the mcp23017.port class )

    One Raspberry Pi can support up to 8 MCP23017 chips with i2cAddresses in
    the range of 0x20 -> 0x27
    """

    ports = {} # key "PortName" constructed "DeviceName.DevicePortName"

    # a collection of mcp23017 ports on one or more mcp23017 chips.

    @classmethod
    def pollAllInputs(cls):
        """
        polls all the input ports
        """
        #TODO write this
        print ( "mcp23017 pollAllInputs() called" )

    @classmethod
    def pollAllOutputs(cls):
        """
        polls all the output ports
        """
        #TODO write this
        print ( "mcp23017 pollAllOutputs() called" )


    @classmethod
    def intialiseAllPorts(cls):
        """
        initialise all the ports
        This should only be called at the end of all the addPort-ing
        """
        #TODO write this
        print ( "mcp23017 initialiseAllPorts() called" )


    @classmethod
    def addPort(cls, portConfig):
        print ( "mcp23017 collection addPort() called for %s " % portConfig['PortName'] )

        # TODO see if PortName already exists , if it does, raise a fatal exception.
        # TODO do we want rules on port naming conventions ? if so do some validation here.
        #TODO write this
        ports[ portConfig['PortName'] ] = Port(portConfig)




