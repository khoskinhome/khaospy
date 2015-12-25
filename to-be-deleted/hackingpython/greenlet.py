#!/usr/bin/python

#from gevent import StreamServer

import gevent

def handle(socket, address):
     print 'new connection!'

server = StreamServer(('127.0.0.1', 1234), handle) # creates a new server
server.start() # start accepting new connections
