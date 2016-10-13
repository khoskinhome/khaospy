#!/usr/bin/python
"""
import json
import yaml
from pprint import pprint

import os

import socket

import khaospy.factory

confdir ='/opt/khaospy/conf/'

hostname = socket.gethostname()

print hostname

#print ( "hostname = " + hostname )

for filename in os.listdir(confdir):

    print ( "######################" )
    print ( filename )

    # TODO There must be a better way to stop unicode silliness with json files :
    with open(confdir + filename ) as data_file:
        jsondata = json.load(data_file)

    confds = yaml.safe_load( json.dumps( jsondata ) )

    print confds["Hostname"]

    if hostname != confds["Hostname"] :
        print ( "    not on this host")
    else :

        print "Build a " + confds["HomeAutoClass"]

        blah = khaospy.factory.Device(confds)

        ##pprint ( confds )

        # build object :

"""
