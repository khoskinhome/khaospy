
from pprint import pprint

class Base(object):
    """
    The Base class of "device"s.
    """

    def __init__(self,deviceConfig):
        self.deviceConfig = deviceConfig
        #pprint(deviceConfig)

    def poll(self):
        # this is an abstract method. All Derived class should override this.
        # TODO should really raise a proper exception.
        assert 0, "abstract poll method called. %s : %s " % ( self.deviceConfig["DeviceName"] , self.deviceConfig["HomeAutoClass"])

    def getConfig(self):
        return self.deviceConfig

