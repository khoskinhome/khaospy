#!/usr/bin/python

from pprint import pprint

#doubles = [2 * n for n in range(50)]
#
#pprint ( doubles )

## sum_of_first_n = sum(xrange(1000000000))


#square is a generator
square = (i*i for i in irange(1000000))
#add the squares
total = 0
for i in square:
   total += i

