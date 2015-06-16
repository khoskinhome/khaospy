
from pprint import pprint

import khaospy

class Base(object):
    """
    The Base class of "device"s.
    """

    def __init__(self,deviceConfig):
        print "BASE __init__ "
        self.deviceConfig = deviceConfig
        self.Ports = {}
        print "BASE adding ports for %s " % self.deviceConfig['DeviceName']
        self.addPortsFromConfig() # delegate to derived class.
        #pprint(deviceConfig)

    def addPortsFromConfig(self):
        """
        This is an abstract method.
        All Derived class should override this.
        TODO should really raise a proper exception.
        """
        assert 0, "abstract addPortFromConfig method called. %s : %s " % ( self.deviceConfig["DeviceName"] , self.deviceConfig["HomeAutoClass"])


    def getConfig(self):
        return self.deviceConfig



