#!/usr/bin/python

from pprint import pprint


def convert_into_bin_array ( num ) :
    bin_array = [0,0,0,0,0,0,0,0]
    i=7
    for bdigit in '{0:08b}'.format( num ) :
        bin_array[i] = bdigit
        i -= 1
    return bin_array

def print_change ( old , new ) :
    # want to have a callback when there is a change.
    old_bstr = convert_into_bin_array( old )
    new_bstr = convert_into_bin_array( new )
    for i in range(7, -1, -1 ) :
        if ( old_bstr[i] != new_bstr[i] ):
            print "bit %i has changed to %s" % ( i, new_bstr[i] )

print_change( 0xff, 0x41 );

