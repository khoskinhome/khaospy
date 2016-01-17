#!/usr/bin/python

# one receiver
import zmq
context = zmq.Context()
socket = context.socket(zmq.PULL)
socket.bind("tcp://*:5556")

while True:
    print socket.recv()
