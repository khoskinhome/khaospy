#!/usr/bin/python
#

import sys
import zmq

port = "5001"

# Socket to talk to server
context = zmq.Context()
socket = context.socket(zmq.SUB)

print "Collecting updates from house temperature monitor server..."
socket.connect ("tcp://pioldwifi:%s" % port)


# Subscribe to zipcode, default is NYC, 10001
topicfilter = "oneWireThermometer"
socket.setsockopt(zmq.SUBSCRIBE, topicfilter)

# so this will form the basis of the rrd updater.
#
# So there will be a central script that will fork processes for all the different IPs we have for all of the pi's

# so one pi will be collected by just one forked process.

# this script is going to have to read the centralised config that will define all the hostnames.
# this centralised config will also give the oneWire thermometers with their 64bit address a "device name" , and a "pretty name" . The pretty name will be much like the device name, but it will have spaces and funny characters allowed.

#TODO  apparently zmq subscribe sockets are fussy about being closed down with ctrl-c, so this needs to be handled in the correct way. The ctrl-c signal needs to be intercepted, and a proper quit made on this daemon.


# Process 5 updates
total_value = 0
for update_nbr in range (60):
    string = socket.recv()
    print string
    #topic, messagedata = string.split()
    #print topic, messagedata

      
