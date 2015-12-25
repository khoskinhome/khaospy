#!/usr/bin/python

import os
from pprint import pprint

i=0

def blah ():
    #    i += 1
    #    print "karl %s" % i
    ret = os.walk('/home/khoskin/github.com/khaospy')
    pprint ( ret )

blah()



