#!/usr/bin/python

# many senders
import zmq
context = zmq.Context()
socket = context.socket(zmq.PUSH)
socket.connect("tcp://pitest:5061")
socket.send("FOO")
