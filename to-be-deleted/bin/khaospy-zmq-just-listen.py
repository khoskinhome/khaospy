#!/usr/bin/python
"""
khaospy-zmq-just-listen.py

Karl Hoskin 30-Dec-2015

subscribes to hosts that are publishing zmq messages

"""

import zmq
import time
import json
import yaml
#import rrdtool

import os.path

from pprint import pprint

import sys
import getopt

print "#####################"
print "Started ",(time.strftime("%Y-%m-%d %H:%M:%S"))

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
socket = context.socket(zmq.SUB)

print "Receiving msgs from %s:%s" % ( host, port )
socket.connect ("tcp://%s:%s" % ( host, port))

topicfilter = ""
socket.setsockopt(zmq.SUBSCRIBE, topicfilter)

while (1) :
    string = socket.recv()
    print string

