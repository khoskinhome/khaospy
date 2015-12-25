#!/usr/bin/python
#

import sys
import zmq

import time
import json
import yaml
#import rrdtool

import os.path

from pprint import pprint

port = "5001"


# This script is to test that stuff is being sent by a "sender" of temperatures.


# Socket to talk to server
context = zmq.Context()
socket = context.socket(zmq.SUB)

print "Collecting updates from house temperature monitor server..."
#socket.connect ("tcp://pioldwifi:%s" % port)
socket.connect ("tcp://piloft:%s" % port)

# Subscribe to zipcode, default is NYC, 10001
topicfilter = "oneWireThermometer"
socket.setsockopt(zmq.SUBSCRIBE, topicfilter)

while (1) :
    string = socket.recv()
    topic, messagedata = string.split(' ', 1 )
    sensorData = yaml.safe_load( messagedata )

    iso8601time = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime( sensorData['EpochTime'] ))
    print "update %s  %s  %s Celcius " % ( iso8601time, sensorData['OneWireAddress'],sensorData['Celsius'])



