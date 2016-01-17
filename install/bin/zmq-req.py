#!/usr/bin/python


# # machine 1
#import zmq
#context = zmq.Context()
#socket = context.socket(zmq.REP)
#socket.bind("tcp://*:5556")
#req = socket.recv()
#socket.send(req)
#
## machine 2
#import zmq
#context = zmq.Context()
#socket = context.socket(zmq.REQ)
#socket.connect("tcp://192.168.1.52:5556")
#socket.send("FOO")
#print socket.recv()
#


# machine 2
import zmq
context = zmq.Context()
socket = context.socket(zmq.REQ)
socket.connect("tcp://pitest:5556")
socket.send("FOO")
print socket.recv()
