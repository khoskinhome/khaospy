#!/usr/bin/python

"""
khaospy-i2c-alarm-poller

polls a Raspberry Pi for its i2c interface for MCP23017
port-expanders, with all the ports set to input.

This is primarily for polling the alarm interface.

Then uses zeromq to publishes the results to a port.

Thus some other process can listen to these reports.

TODO still need to get the PORT it pushes data to from the config.
Saying that I can't see more than one of these running on a machine.
So a standard port of 5051 will work okay.


By Karl "khaos" Hoskin 2015-10-27
"""

import smbus
import zmq
import sys
import os
import os.path
import time
import re
import json
from pprint import pprint

port = "5051"

context = zmq.Context()
socket = context.socket(zmq.PUB)
socket.bind("tcp://*:%s" % port)

print os.getcwd()

# smbus : Rev 2 Pi uses 1 ,  Rev 1 Pi uses 0
bus = smbus.SMBus(0)

# if IODIR bit is set to 1 it is an input
# if IODIR bit is set to 0 it is an output
IODIRA = 0x00 # Pin direction register
IODIRB = 0x01 # Pin direction register

GPIOA  = 0x12 # Register for inputs
GPIOB  = 0x13 # Register for inputs

gpio_map = {}
gpio_map[GPIOA]="GPIOA"
gpio_map[GPIOB]="GPIOB"

i2cAddrs = [ 0x20, 0x21 ]

mapping={}
for i2caddr in i2cAddrs:
    mapping[i2caddr]={}
    for gpio in [GPIOA, GPIOB]:
        mapping[i2caddr][gpio_map[gpio]]={}

mapping[0x20]["GPIOB"][0]="alarm-1"
mapping[0x20]["GPIOB"][1]="alarm-2"
mapping[0x20]["GPIOB"][2]="alarm-3"
mapping[0x20]["GPIOB"][3]="alarm-4"
mapping[0x20]["GPIOB"][4]="alarm-5"
mapping[0x20]["GPIOB"][5]="alarm-6"
mapping[0x20]["GPIOB"][6]="alarm-7"
mapping[0x20]["GPIOB"][7]="alarm-8"

mapping[0x20]["GPIOA"][7]="alarm-9"
mapping[0x20]["GPIOA"][6]="alarm-10"
mapping[0x20]["GPIOA"][5]="alarm-11"
mapping[0x20]["GPIOA"][4]="alarm-12"
mapping[0x20]["GPIOA"][3]="alarm-13"
mapping[0x20]["GPIOA"][2]="alarm-14"
mapping[0x20]["GPIOA"][1]="alarm-15"
mapping[0x20]["GPIOA"][0]="alarm-16"

mapping[0x21]["GPIOB"][0]="alarm-17"
mapping[0x21]["GPIOB"][1]="alarm-18"
mapping[0x21]["GPIOB"][2]="alarm-19"
mapping[0x21]["GPIOB"][3]="alarm-20"
mapping[0x21]["GPIOB"][4]="alarm-21"
mapping[0x21]["GPIOB"][5]="alarm-22"
mapping[0x21]["GPIOB"][6]="alarm-23"
mapping[0x21]["GPIOB"][7]="alarm-24"

mapping[0x21]["GPIOA"][7]="alarm-25"
mapping[0x21]["GPIOA"][6]="alarm-26"
mapping[0x21]["GPIOA"][5]="alarm-27"
mapping[0x21]["GPIOA"][4]="alarm-28"
mapping[0x21]["GPIOA"][3]="tamp-1"
mapping[0x21]["GPIOA"][2]="tamp-2"
mapping[0x21]["GPIOA"][1]="tamp-3"
mapping[0x21]["GPIOA"][0]="tamp-4"

def convert_into_bin_array ( num ) :
    bin_array = [0,0,0,0,0,0,0,0]
    i=7
    for bdigit in '{0:08b}'.format( num ):
        bin_array[i] = bdigit
        i -= 1
    return bin_array

def print_change ( old , new , gpio, i2caddr ) :

    if old==new: return
    # want to have a callback when there is a change.
    old_bstr = convert_into_bin_array( old )
    new_bstr = convert_into_bin_array( new )
    for i in range(7, -1, -1 ) :
        if ( old_bstr[i] != new_bstr[i] ):
            print "0x%x %s bit %i has changed to %s" % ( i2caddr, gpio_map[gpio], i, new_bstr[i] )
            print " alarm  %s " % mapping[i2caddr][gpio_map[gpio]][i]

lastpoll = {}

for i2caddr in i2cAddrs:
    print "Setup i2c address 0x%x as input " % i2caddr;
    for iodir in [ IODIRA, IODIRB ] :
        # setting iodir to 0xFF sets all bits to input
        bus.write_byte_data(i2caddr,iodir,0xFF)

    lastpoll[i2caddr]={}
    for gpio in [ GPIOA, GPIOB ] :
        lastpoll[i2caddr][gpio] = 0

# pprint( lastpoll )

while True:
    for i2caddr in i2cAddrs:
        #output = "%x " % i2caddr
        for gpio in [ GPIOA, GPIOB ]:
            try :
                MySwitch = bus.read_byte_data(i2caddr,gpio)
                #output += "%x " % ( gpio )
                #output += '{0:08b}   '.format( MySwitch )
                print_change( lastpoll[i2caddr][gpio] , MySwitch, gpio, i2caddr )
                lastpoll[i2caddr][gpio] = MySwitch
                #        print output
                #        print "############################################"
                #        time.sleep(1)
            except IOError, e:
                pass


# plan
######
# ("send" here refers to publishing to the zeromq port.)
# So once every 60 seconds send the state of all ports.
# Don't send them all at once.
# Send the "unchanged" ports 8 at a time. ( 1 bytes worth )
# i.e. 
#   all of 0x20 GPIOA once every 60s after the poller has run 15 seconds, and then every 60 seconds.
#   all of 0x20 GPIOB once every 60s after the poller has run 35 seconds, and then every 60 seconds.
#   all of 0x21 GPIOA once every 60s after the poller has run 45 seconds, and then every 60 seconds.
#   all of 0x21 GPIOB once every 60s after the poller has run 60 seconds, and then every 60 seconds.
#
# The "change" function can be altered to do this.
#
# Any of the 32 ports that changes is sent immediately.
#
# The message sent will indicate if the port is the same or has changed.
#
# 
#





#    print "###########################"
#    for thdir in os.listdir(oneWireDir):
#        tpath = oneWireDir + thdir
#        if os.path.isdir(tpath):
#            tpath += "/w1_slave"
#            if os.path.isfile(tpath):
#
#                #time.sleep(1) # give the processor a break
#                print tpath
#                with open(tpath) as x: data = x.readlines()
#
#                jsonbody={}
#                jsonbody['OneWireAddress']=thdir
#                jsonbody['HomeAutoClass']="oneWireThermometer"
#                jsonbody['EpochTime']=time.time()
#
#                if data[0].strip()[-3:] == "YES":
#                    jsonbody['Celsius']=float(data[1].split("=")[1])/1000
#                else:
#                    jsonbody['Celsius']="ERROR: NOT READY !!"
#                       
#                print json.dumps( jsonbody ) 
#                socket.send("%s %s" % (jsonbody['HomeAutoClass'], json.dumps( jsonbody )))
#
