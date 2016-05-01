#!/usr/bin/python

"""
khaospy-one-wired-sender

By Karl Hoskin 2015-06-23 and 2015-12-25

Polls a Raspberry Pi for its oneWire connected DS18b20 thermometers.

Then uses zeromq to publish the results to a port.

khaospy-one-wired-receiver.py listens to these ports. ( and creates RRDs )

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

print "#####################"
print "Started ",(time.strftime("%Y-%m-%d %H:%M:%S"))

# cli options :
stdout_freq = 0
port = 5001
polleveryseconds=30

options, remainder = getopt.getopt(sys.argv[1:], 'p:f:s:', [ 'port=', 'stdout_freq=','poll=' ])

for opt, arg in options:
    if opt in ('-f', '--stdout_freq'):
        stdout_freq = int(arg)
    elif opt in ('-p', '--port'):
        port = int(arg)
    elif opt in ('-s', '--poll'):
        polleveryseconds = int(arg)

# stdout_freq is the amount of seconds readings will go to STDOUT.
print 'STDOUT_FREQ -f --stdout_freq (seconds) :', stdout_freq
print 'PORT        -p --port                  :', port
print 'POLL        -s --poll        (seconds) :', polleveryseconds

context = zmq.Context()
socket = context.socket(zmq.PUB)
socket.bind("tcp://*:%s" % port)

os.system('modprobe w1-gpio')
os.system('modprobe w1-therm')

oneWireDir='/sys/bus/w1/devices/'
os.chdir( oneWireDir )

lastpoll=time.time() - polleveryseconds

last_stdout=time.time() - stdout_freq;

while True:
    while time.time() < lastpoll + polleveryseconds:
        time.sleep(0.2)

    lastpoll=time.time()

    print_to_stdout = False

    for thdir in os.listdir(oneWireDir):
        tpath = oneWireDir + thdir
        if os.path.isdir(tpath):
            tpath += "/w1_slave"
            if os.path.isfile(tpath):

                with open(tpath) as x: data = x.readlines()

                jsonbody={}
                jsonbody['OneWireAddress']=thdir
                jsonbody['HomeAutoClass']="oneWireThermometer"
                jsonbody['EpochTime']=time.time()
 
                if data[0].strip()[-3:] == "YES":
                    jsonbody['Celsius']=float(data[1].split("=")[1])/1000
                else:
                    jsonbody['Celsius']="ERROR: NOT READY !!"

                if time.time() > last_stdout + stdout_freq:
                    # print tpath
                    print json.dumps( jsonbody )
                    print_to_stdout = True

                socket.send("%s %s" % (jsonbody['HomeAutoClass'], json.dumps( jsonbody )))

    if time.time() > last_stdout + stdout_freq and print_to_stdout:
        last_stdout = time.time()
