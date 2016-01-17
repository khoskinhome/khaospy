#!/usr/bin/python

# many senders
import zmq
context = zmq.Context()
socket = context.socket(zmq.PUSH)
socket.connect("tcp://pitest:5556")
socket.send("FOO")
