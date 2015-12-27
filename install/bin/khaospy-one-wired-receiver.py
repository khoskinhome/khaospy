#!/usr/bin/python

"""
khaospy-one-wired-receiver.py

Karl Hoskin 25-Dec-2015

subscribes to hosts that are "sending" temperature readings.

If an rrd doesn't exist it creates the rrd.

Updates the rrds with the data received.

TODO  apparently zmq subscribe sockets are fussy about being closed down with ctrl-c, so this needs to be handled in the correct way. The ctrl-c signal needs to be intercepted, and a proper quit made on this script

"""
"""
It would be nicer to have one script that works out what hosts are publishing "one-wire" temperatures,
subscribes to them all and updates the rrds.

probably going to do this with the perl "AnyEvent" script I have.


"""
import zmq

import time
import json
import yaml
import rrdtool

import os.path

from pprint import pprint

import sys
import getopt

# cli options :
host = ''
port = 5001

options, remainder = getopt.getopt(sys.argv[1:], 'h:p:', ['host=', 'port=' ])

for opt, arg in options:
    if opt in ('-h', '--host'):
        host = arg
    elif opt in ('-p', '--port'):
        port = arg

print 'HOST -h --host :', host
print 'PORT -p --port :', port

# Socket to talk to server
context = zmq.Context()
socket = context.socket(zmq.SUB)

print "Receiving temperature senders from %s:%s" % ( host, port )
socket.connect ("tcp://%s:%s" % ( host, port ))

# make sure there is a slash on the end of this :
rrddatapath ='/opt/khaospy/rrd/'
if not os.path.isdir(rrddatapath) :
    # print "no rrddatapath %s" % rrddatapath
    raise NameError( "no rrddatapath %s" % rrddatapath )

topicfilter = "oneWireThermometer"
socket.setsockopt(zmq.SUBSCRIBE, topicfilter)

while (1) :
    string = socket.recv()
    topic, messagedata = string.split(' ', 1 )
    sensorData = yaml.safe_load( messagedata )

    #print "Address    = %s " % sensorData['OneWireAddress']
    #print "Epoch time = %s " % sensorData['EpochTime']
    #print "Celsius    = %s " % sensorData['Celsius']

    rrdname = rrddatapath + "/" + sensorData['OneWireAddress']
    if not os.path.isfile(rrdname):
        print "creating rrd %s" % rrdname

        # The RRAs in the following will collect data for :

        #RRA:AVERAGE:0.5:1:1440       1 day   datapoints every    1 min.  ( 1day )
        #RRA:AVERAGE:0.5:4:1440       4 days  datapoints every    4 mins. ( 1/2 week )
        #RRA:AVERAGE:0.5:8:1440       8 days  datapoints every    8 mins. ( 1 week )
        #RRA:AVERAGE:0.5:32:1440     32 days  datapoints every   32 mins. ( 1 month )
        #RRA:AVERAGE:0.5:60:17520   730 days  datapoints every   60 mins. ( 2 years )
        #
        rrdtool.create( rrdname , '--start', 'now', '--step', '60', \
        'DS:a:GAUGE:120:-50:50',\
        'RRA:AVERAGE:0.5:1:1440',\
        'RRA:AVERAGE:0.5:4:1440',\
        'RRA:AVERAGE:0.5:8:1440',\
        'RRA:AVERAGE:0.5:32:1440',\
        'RRA:AVERAGE:0.5:60:17520' );

    iso8601time = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime( sensorData['EpochTime'] ))
    rrdtool.update( rrdname, "%s:%s" % (sensorData['EpochTime'], sensorData['Celsius'] ))

    print "update %s  %s  %s Celcius " % ( iso8601time, sensorData['OneWireAddress'],sensorData['Celsius'])

