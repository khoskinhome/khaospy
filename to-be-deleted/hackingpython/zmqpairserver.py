#import zmq
#import random
#import sys
#import time
#
#port = "5556"
#context = zmq.Context()
#socket = context.socket(zmq.PAIR)
#socket.bind("tcp://*:%s" % port)
#
#while True:
#    socket.send("Server message to client3")
#    msg = socket.recv()
#    print msg
#    time.sleep(1)
#

import time
import zmq

context = zmq.Context()
socket = context.socket(zmq.PAIR)
socket.bind("tcp://*:5555")

while True:
    # Wait for next request from client
    message = socket.recv()
    print("Received request: %s" % message)

    # Do some 'work'
    time.sleep(1)

    # Send reply back to client
    socket.send(b"World")


