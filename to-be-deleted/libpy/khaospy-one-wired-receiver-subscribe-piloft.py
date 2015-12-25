#!/usr/bin/python
#

# TO BE DELETED.
# THIS HAS BEEN REPLACED BY khaospy-one-wired-receiver.py


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

print "Collecting updates from piloft temperature monitor server..."
socket.connect ("tcp://piloft:%s" % port)

rrddatapath ='/opt/khaospy/rrd/' # make sure there is a slash on the end of this !
if not os.path.isdir(rrddatapath) :
    # print "no rrddatapath %s" % rrddatapath
    raise NameError( "no rrddatapath %s" % rrddatapath )


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
##for update_nbr in range (1):

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
        #rrdtool.create( rrdname , '--start', 'now', '--step', '60', 'DS:a:GAUGE:120:-50:50', 'RRA:AVERAGE:0.5:1:12', 'RRA:AVERAGE:0.5:1:288', 'RRA:AVERAGE:0.5:12:168', 'RRA:AVERAGE:0.5:12:720', 'RRA:AVERAGE:0.5:288:365');
        rrdtool.create( rrdname , '--start', 'now', '--step', '60', 'DS:a:GAUGE:120:-50:50', 'RRA:AVERAGE:0.5:1:1440', 'RRA:AVERAGE:0.5:4:1440', 'RRA:AVERAGE:0.5:8:1440', 'RRA:AVERAGE:0.5:32:1440', 'RRA:AVERAGE:0.5:96:1440', 'RRA:AVERAGE:0.5:183:1440', 'RRA:AVERAGE:0.5:365:1440');

    iso8601time = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime( sensorData['EpochTime'] ))
    print "update %s  %s  %s Celcius " % ( iso8601time, sensorData['OneWireAddress'],sensorData['Celsius'])

    rrdtool.update( rrdname, "%s:%s" % (sensorData['EpochTime'], sensorData['Celsius'] ))

    





#rrds_to_filename = {
#  "a" : "/sys/bus/w1/devices/28-011465167eff/w1_slave",
#  "b" : "/sys/bus/w1/devices/28-021463277cff/w1_slave",
#  "c" : "/sys/bus/w1/devices/28-02146329ceff/w1_slave",
#  "d" : "/sys/bus/w1/devices/28-0214632d16ff/w1_slave",
#  "e" : "/sys/bus/w1/devices/28-021463423bff/w1_slave",
#}
#
#def read_temperature(file):
#  tfile = open(file)
#  text = tfile.read()
#  tfile.close()
#  lines = text.split("\n")
#  if lines[0].find("YES") > 0:
#    temp = float((lines[1].split(" ")[9])[2:])
#    temp /= 1000
#    return temp
#  return ERROR_TEMP
#
#def read_all():
#  template = ""
#  update = "N:"
#  for rrd in rrds_to_filename:
#    template += "%s:" % rrd
#    temp = read_temperature(rrds_to_filename[rrd])
#    update += "%f:" % temp
#  update = update[:-1]
#  template = template[:-1]
#  rrdtool.update(databaseFile, "--template", template, update)
#  print databaseFile
#  print template
#  print update
#
#




# /opt/khaospy/rrd/

## rrdtool create temperature.rrd   --start now --step 60     DS:a:GAUGE:120:-50:50   RRA:AVERAGE:0.5:1:12     RRA:AVERAGE:0.5:1:288     RRA:AVERAGE:0.5:12:168     RRA:AVERAGE:0.5:12:720     RRA:AVERAGE:0.5:288:365



#
#
#ret = rrdtool.create("example.rrd", "--step", "1800", "--start", '0',
#    "DS:metric1:GAUGE:2000:U:U",
#    "DS:metric2:GAUGE:2000:U:U",
#    "RRA:AVERAGE:0.5:1:600",
#    "RRA:AVERAGE:0.5:6:700",
#    "RRA:AVERAGE:0.5:24:775",
#    "RRA:AVERAGE:0.5:288:797",
#   "RRA:MAX:0.5:1:600",
#   "RRA:MAX:0.5:6:700",
#   "RRA:MAX:0.5:24:775",
#   "RRA:MAX:0.5:444:797")
#
      
