import json
import yaml

from pprint import pprint

import os
from os import path

import socket

import khaospy
from khaospy import devicef

from khaospy import devicec

#class
## ./install/libpy/khaospy-daemon-run.py:10:#./install/libpy/khaospy/daemon.py # TODO rm this line

class Runner(object):
    confdir ='/opt/khaospy/conf/'
    hostname = socket.gethostname()
    runDeviceCollection = khaospy.devicec.Collection()

    @classmethod
    def run(cls):
        cls.buildAllFromConfig()
        #cls.runDeviceCollection.pprintAllDeviceConfigs()
        """
        mlsw = khaospy.mcp23017MultiLightSingleWayManual.Device()
        mlsw.getSwitchMainsState()

        ## ./install/libpy/khaospy/mcp23017SingleLightTwoWayManual.py
        sltw = khaospy.mcp23017SingleLightTwoWayManual.Device()

        sltw.pollMainsDetector()

        # need to load the config.
        # the config is going to have every automation "device" on all Pis.
        # we only need to instantiate the ones for this Pi. As identified by the IP address.

        # That will require building a "Device" of the correct type.
        # all device's have a "poll" method.
        # this method refeshes the "inputs" that the device has.
        # i.e. a Light circuit will have switch or light states.
        """


    @classmethod
    def buildAllFromConfig(cls):
        print ("Building all the devices from the config ....")
        for filename in os.listdir(cls.confdir):

            fileparts = os.path.splitext(filename)
            deviceName = fileparts[0]

            with open(cls.confdir + filename ) as data_file:
                jsondata = json.load(data_file)

            # TODO There must be a better way to stop unicode silliness with json files :
            config = yaml.safe_load( json.dumps( jsondata ) )

            print ( "######################" )
            if cls.hostname != config["Hostname"] :
                print ( "Device %s is on host %s (not this host)" % ( deviceName , config["Hostname"] ) )
            else :
                print ( "Device %s is a %s" % ( deviceName , config["HomeAutoClass"]))

                config["DeviceName"] = deviceName
                cls.runDeviceCollection.addDevice(config)

