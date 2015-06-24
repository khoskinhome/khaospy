#!/usr/bin/python
import zmq

print zmq.pyzmq_version()

import time

context = zmq.Context()

socket = context.socket(zmq.REP)


