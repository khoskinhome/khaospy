#!/usr/bin/python

"""
khaospy-one-wired-sender

By Karl Hoskin 2015-06-23 and 2015-12-25

Polls a Raspberry Pi for its oneWire connected DS18b20 thermometers.

Then uses zeromq to publishes the results to a port.

khaospy-one-wired-receiver.py listens to these ports.

"""

import zmq
import os
import os.path
import time
import re
import json
from pprint import pprint

import sys
import getopt

# cli options :
verbose = False
port = 5001

options, remainder = getopt.getopt(sys.argv[1:], 'p:v', [ 'port=', 'verbose', ])

for opt, arg in options:
    if opt in ('-v', '--verbose'):
        verbose = True
    elif opt in ('-p', '--port'):
        port = arg

print 'VERBOSE   :', verbose
print 'PORT      :', port

context = zmq.Context()
socket = context.socket(zmq.PUB)
socket.bind("tcp://*:%s" % port)

os.system('modprobe w1-gpio')
os.system('modprobe w1-therm')

oneWireDir='/sys/bus/w1/devices/'
os.chdir( oneWireDir )


##TODO get this modprobe to actually work
#if not os.path.isdir(oneWireDir):
#    os.system("modprobe w1-gpio")
#    os.system("modprobe w1-therm")

print os.getcwd()

polleveryseconds=30

lastpoll=time.time() - polleveryseconds

while True:
    while time.time() < lastpoll + polleveryseconds:
        time.sleep(0.2)

    lastpoll=time.time()
    print "###########################"
    for thdir in os.listdir(oneWireDir):
        tpath = oneWireDir + thdir
        if os.path.isdir(tpath):
            tpath += "/w1_slave"
            if os.path.isfile(tpath):

                #time.sleep(1) # give the processor a break
                print tpath
                with open(tpath) as x: data = x.readlines()

                jsonbody={}
                jsonbody['OneWireAddress']=thdir
                jsonbody['HomeAutoClass']="oneWireThermometer"
                jsonbody['EpochTime']=time.time()

                if data[0].strip()[-3:] == "YES":
                    jsonbody['Celsius']=float(data[1].split("=")[1])/1000
                else:
                    jsonbody['Celsius']="ERROR: NOT READY !!"

                print json.dumps( jsonbody )
                socket.send("%s %s" % (jsonbody['HomeAutoClass'], json.dumps( jsonbody )))

