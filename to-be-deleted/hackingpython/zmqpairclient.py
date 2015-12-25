
#
#import zmq
#import random
#import sys
#import time
#
#port = "5556"
#context = zmq.Context()
#socket = context.socket(zmq.PAIR)
#socket.connect("tcp://localhost:%s" % port)
#
#while True:
#    msg = socket.recv()
#    print msg
#    socket.send("client message to server1")
#    socket.send("client message to server2")
#    time.sleep(1)
#

import zmq

context = zmq.Context()

# Socket to talk to server
print("Connecting to hello world server")
socket = context.socket(zmq.PAIR)
socket.connect("tcp://localhost:5555")

# Do 10 requests, waiting each time for a response
for request in range(10):
    print("Sending request %s " % request)
    socket.send(b"Hello")

    # Get the reply.
    message = socket.recv()
    print("Received reply %s [ %s ]" % (request, message))
