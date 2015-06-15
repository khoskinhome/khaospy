import json
import yaml

from pprint import pprint

import os
import socket

import khaospy
from khaospy import devicef

confdir ='/opt/khaospy/conf/'

hostname = socket.gethostname()

print hostname


# ./install/libpy/khaospy/utils.py

# ./install/libpy/khaospy/config.py
# import khaospy.config

#print "in khaospy.daemon :"
#print ( dir(khaospy) )


def run():
    buildAllFromConfig()
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

#

def buildAllFromConfig():

    print ("Building all the devices from the config ....")
    #print ( "hostname = " + hostname )

    for filename in os.listdir(confdir):

        print ( "######################" )
        print ( filename )

        # TODO There must be a better way to stop unicode silliness with json files :
        with open(confdir + filename ) as data_file:
            jsondata = json.load(data_file)

        config = yaml.safe_load( json.dumps( jsondata ) )

        print config["Hostname"]

        if hostname != config["Hostname"] :
            print ( "    not on this host")
        else :

            print "Build a " + config["HomeAutoClass"]

            # TODO need to remove ".json" from filename before it gets passes as the deviceName
            config["DeviceName"] = filename

            blah = khaospy.devicef.factory( config )

            ##pprint ( config )

            # build object :



