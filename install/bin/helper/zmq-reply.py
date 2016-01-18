#!/usr/bin/python


 # machine 1
import zmq
context = zmq.Context()
socket = context.socket(zmq.REP)
socket.bind("tcp://*:5556")
req = socket.recv()
socket.send(req + "dog" ) 


