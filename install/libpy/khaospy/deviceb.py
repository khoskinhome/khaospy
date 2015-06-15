
from pprint import pprint

import khaospy

from khaospy import mcp23017

class Base(object):
    """
    The Base class of "device"s.
    """

    def __init__(self,deviceConfig):
        print "BASE __init__ "
        self.deviceConfig = deviceConfig
        #pprint(deviceConfig)

    def poll(self):
        # this is an abstract method. All Derived class should override this.
        # TODO should really raise a proper exception.
        assert 0, "abstract poll method called. %s : %s " % ( self.deviceConfig["DeviceName"] , self.deviceConfig["HomeAutoClass"])

    def getConfig(self):
        return self.deviceConfig


    def addMCP20317Ports(self):
        # the __init__ in the derived class should call the correct addXXXXXXPorts
        print " BASE adding the MCP23017 ports for %s " % self.deviceConfig['DeviceName']


    def addOneWirePorts(self):
        # the __init__ in the derived class should call the correct addXXXXXXPorts
        print " BASE adding the one wire ports for %s " % self.deviceConfig['DeviceName']
