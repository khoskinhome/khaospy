
from pprint import pprint

import khaospy
from khaospy import devicef

class Collection(object):
    """
    collection of devices
    """
    allDevices = {} # indexed on DeviceName

    @classmethod
    def addDevice(cls,deviceConfig):
        #
        cls.allDevices[deviceConfig['DeviceName']] = khaospy.devicef.factory( deviceConfig )
        return cls.allDevices[deviceConfig['DeviceName']]

    @classmethod
    def pprintAllDeviceConfigs(cls):
        for d in cls.allDevices:
            pprint ( cls.allDevices[d].getConfig() )

