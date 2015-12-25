#!/usr/bin/python

"""
khaospy-one-wired-sender
By Karl Hoskin 2015-06-23 and 2015-12-25

polls a Raspberry Pi for its oneWire connected DS18b20
thermometers.

Then uses zeromq to publishes the results to a port.

Thus some other process can listen to these reports.


TODO pass in the params of
    port  ( default 5001 )
for where to subscribe the listener to.

"""

import zmq
import sys
import os
import os.path
import time
import re
import json
from pprint import pprint

port = "5001"

context = zmq.Context()
socket = context.socket(zmq.PUB)
socket.bind("tcp://*:%s" % port)

oneWireDir='/sys/bus/w1/devices/'
os.chdir( oneWireDir )


#TODO get this modprobe to actually work
if not os.path.isdir(oneWireDir):
    os.system("modprobe w1-gpio")
    os.system("modprobe w1-therm")

print os.getcwd()

polleveryseconds=30
#polleveryseconds=1
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

