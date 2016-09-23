import json
import yaml

from pprint import pprint

import os
from os import path

import socket

import khaospy
from khaospy import devicef
from khaospy import devicec
from khaospy import exception
from khaospy import oneWire
from khaospy import mcp23017

#class
## ./install/libpy/khaospy-daemon-run.py:10:#./install/libpy/khaospy/daemon.py # TODO rm this line
confdir  = '/opt/khaospy/conf/'
hostname = socket.gethostname()

class Runner(object):

    @classmethod
    def run(cls):
        """
        # need to load the config.
        # the config is going to have every automation "device" on all Pis.
        # we only need to instantiate the ones for this Pi. As identified by the IP address.
        """
        cls.buildAllFromConfig()
        # khaospy.devicec.collection.pprintAllDeviceConfigs()

        """
        # That will require building a "Device" of the correct type.
        # all device's have a "poll" method.
        # this method refeshes the "inputs" that the device has.
        # i.e. a Light circuit will have switch or light states.

        In perl ( I gotta do in python ! )
        while (1) {
        """
        mcp23017.collection.pollAllInputs()
        mcp23017.collection.pollAllOutputs()

        oneWire.collection.pollAllInputs()
        oneWire.collection.pollAllOutputs()
        

        #TODO write this

        # listens to a port accepting http requests.
        # the http requests have to be authorised.
        # REST interface , with JSON body.
        #
        # the http response also has a JSON body.
        #
        # The listener accepts command requests.
        # These requests are broadly :
        #   1) I want to start/stop listening to the status of a specific DeviceName . ( and frequency of updates )
        #   2) I want to start/stop listening to the status of ALL devices that you have. ( and frequency of updates )
        #        ( these listen requests  are pushed onto a informListener object.  )
        #
        #   3) I want to know immediately the status of a specific DeviceName
        #       this is immediately replied to
        #
        #   4) I want to know immediately the status of a all devices that you have
        #       this is immediately replied to
        #
        #   5) I want to change the state / configuration of a Device
        #       this is pushed on  the deviceCommandQueue. ( i.e. DeviceName ON )
        #
        #   6) I want to know all the devices you have, and their type, and maybe configuration.
        #       this is immediately replied to
        #
        #   7) I want to know the specific configuration of a DeviceName
        #       this is immediately replied to
        #
        #
        # Any change state of device requests are pushed to the device's command queue.
        # The devices will pull their commands from their queue when they are polled()
        # The requests are "switch on / off / toggle" , they are not "current state" requests.
        #
        # So the following will get a device to look at it command queue , and it's own direct inputs
        # ( currently just from an mcp23017 gpio input )
        devicec.collection.pollAll()

        #
        # get commands ( i.e. set DeviceName ON )
        # deviceCommandQueue.poll()

        # push out the current status of devices to any "listenners"
        # pushCurrentStatus()

        """
        }
        """


    @classmethod
    def buildAllFromConfig(cls):
        print ("Building all the devices from the config ....")
        for filename in os.listdir(confdir):

            fileparts = os.path.splitext(filename)
            deviceName = fileparts[0]

            if not cls._validateDeviceName(deviceName) :
                raise khaospy.exception.BadConfiguration("deviceName '%s' is invalid" % deviceName )


            with open(confdir + filename ) as data_file:
                jsondata = json.load(data_file)

            # TODO There must be a better way to stop unicode silliness with json files :
            config = yaml.safe_load( json.dumps( jsondata ) )

            print ( "######################" )
            if hostname != config["Hostname"] :
                print ( "Device %s is on host %s (not this host)" % ( deviceName , config["Hostname"] ) )
            else :
                print ( "Device %s is a %s" % ( deviceName , config["HomeAutoClass"]))

                config["DeviceName"] = deviceName

                devicec.collection.addDevice(config)

        mcp23017.collection.intialiseAllPorts()
        oneWire.collection.intialiseAllPorts()



    @classmethod
    def _validateDeviceName(cls, deviceName ) :
        """
        The rules of this validation are that the devicename must only be:
        ASCII a-z A-Z 0-9 <underscore> <hyphen> 
        i.e the perl character class regex would be :
        [a-zA-Z0-9\-_]
        You would be unwise to have 2 devices with the same name but with different case.
        This would work, but it isn't recommended.

        This method returns True on a validDeviceName otherwise returns False.

        """
        #TODO write this
        return True
