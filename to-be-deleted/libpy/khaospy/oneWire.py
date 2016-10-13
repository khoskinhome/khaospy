
import khaospy
from khaospy import exception

class port(object):
    # a single port for a one wire device
    """
    a single port for a one wire device .
    what will the configs for this be ?
    I can think of only 2 at present that relate to the DS18b20 thermometers
    and they are :-

        GPIO on the Pi ( this might be hard-coded to 4 )
        64 bit address of the one wire device.

    If we are going to do more oneWire stuff than just thermometers, i.e. stuff
    that does input as well as output then this will need all the
    settings just like the mcp23017 port.

    until there are oneWire devices that do that on this home auto system
    I can't be bothered to write the software for it.

    """
    def __init__(self,portConfig):
        print ( "oneWire port  __init__() called for %s " % portConfig['PortName'] )
        self.portConfig = portConfig
        #TODO write this

##############################################################
# should I use smbus or quick2wire ?  dunno.

class collection(object):
    """
    Has all the one wire ports

    apparently one GPIO-4 port can only support upto 10 DS18B20 thermometers.
    this i will have to check.
    """

    ports = {} # key "PortName" constructed "DeviceName.DevicePortName"

    @classmethod
    def pollAllInputs(cls):
        """
        polls all the input ports
        """
        #TODO write this
        print ( "oneWire pollAllInputs() called" )

    @classmethod
    def pollAllOutputs(cls):
        """
        polls all the output ports

        I don't think we need the following for oneWire.
        That is unless we do get some output to something oneWire-ish
        There is not any outputing necessary to a DS18b20 thermometer.
        """
        #TODO write this
        print ( "oneWire pollAllOutputs() called" )

    @classmethod
    def intialiseAllPorts(cls):
        """
        initialise all the ports
        This should only be called at the end of all the addPort-ing

        I don't think we need the following for oneWire.
        TODO be confirmed if we need this or not.
        """
        #TODO write this
        print ( "oneWire intialiseAllPorts() called " )

    @classmethod
    def addPort(cls, portConfig):
        print ( "oneWire addPort() called for " + portConfig['PortName'] )
        #TODO write this

