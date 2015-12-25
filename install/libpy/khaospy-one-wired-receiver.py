#!/usr/bin/python


"""
Karl Hoskin 25-Dec-2015

# so this will form the basis of the rrd updater.
#
# So there will be a central script that will fork processes for all the different IPs we have for all of the pi's

# so one pi will be collected by just one forked process.

# this script is going to have to read the centralised config that will define all the hostnames.
# this centralised config will also give the oneWire thermometers with their 64bit address a "device name" , and a "pretty name" . The pretty name will be much like the device name, but it will have spaces and funny characters allowed.

#TODO  apparently zmq subscribe sockets are fussy about being closed down with ctrl-c, so this needs to be handled in the correct way. The ctrl-c signal needs to be intercepted, and a proper quit made on this daemon.

TODO pass in the params of
    host  ( no default , will fail if this isn't supplied )
    port  ( default 5001 )
for where to subscribe the listener to.

"""

import sys
import zmq

import time
import json
import yaml
import rrdtool

import os.path

from pprint import pprint

port = "5001"

# Socket to talk to server
context = zmq.Context()
socket = context.socket(zmq.SUB)

print "Collecting updates from temperature senders"
#socket.connect ("tcp://pioldwifi:%s" % port)
socket.connect ("tcp://piloft:%s" % port)

rrddatapath ='/opt/khaospy/rrd/' # make sure there is a slash on the end of this !
if not os.path.isdir(rrddatapath) :
    # print "no rrddatapath %s" % rrddatapath
    raise NameError( "no rrddatapath %s" % rrddatapath )


# Subscribe to zipcode, default is NYC, 10001
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
    print "update %s  %s  %s Celcius " % ( iso8601time, sensorData['OneWireAddress'],sensorData['Celsius'])

    rrdtool.update( rrdname, "%s:%s" % (sensorData['EpochTime'], sensorData['Celsius'] ))

