#!/usr/bin/python

import getopt
import sys

verbose = False
host = ''
port = 5001

print 'ARGV      :', sys.argv[1:]

options, remainder = getopt.getopt(sys.argv[1:], 'h:p:v', ['host=', 'port=', 'verbose', ])

for opt, arg in options:
    if opt in ('-h', '--host'):
        host = arg
    elif opt in ('-v', '--verbose'):
        verbose = True
    elif opt in ('-p', '--port'):
        port = arg

print 'VERBOSE   :', verbose
print 'HOST      :', host
print 'PORT      :', port
print 'REMAINING :', remainder

