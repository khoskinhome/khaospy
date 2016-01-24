#!/usr/bin/python
"""
khaospy-zmq-just-listen.py

Karl Hoskin 16-Jan-2016

subscribes to hosts that are publishing zmq messages

"""

import zmq
import time
#import rrdtool

import os.path

from pprint import pprint

import json
import sys
import getopt


# cli options :
host = ''
port = 5001

options, remainder = getopt.getopt(sys.argv[1:], 'h:p:', ['host=', 'port=', ])

for opt, arg in options:
    if opt in ('-h', '--host'):
        host = arg
    elif opt in ('-p', '--port'):
        port = arg

print 'HOST      :', host
print 'PORT      :', port

# Socket to talk to server
context = zmq.Context()
socket = context.socket(zmq.PUB)

hostnport = "tcp://%s:%s" % ( host, port )
socket.bind (hostnport)

print "Sending a fake json msg to %s" % ( hostnport )

# socket.send("somefrickin {A message}")
jsonbody={}
jsonbody['OneWireAddress']="blah"
jsonbody['HomeAutoClass']="oneWireThermometer"
jsonbody['EpochTime']=time.time()

while True:
    socket.send("%s %s" % (jsonbody['HomeAutoClass'], json.dumps( jsonbody )))
    time.sleep(3)
