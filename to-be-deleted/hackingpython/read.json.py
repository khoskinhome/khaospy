#!/usr/bin/python

import sys
import json

import os

if 'PYTHONPATH' in os.environ :
    print (os.environ['PYTHONPATH'])


print ( sys.path )

print (os.environ['HOME'])

#print __name__







#
#from functools import wraps
#
#
#def beg(target_function):
#    @wraps(target_function)
#    def wrapper(*args, **kwargs):
#        msg, say_please = target_function(*args, **kwargs)
#        if say_please:
#            return "{} {}".format(msg, "Please! I am poor :(")
#        return msg
#
#    return wrapper
#
#
#@beg
#def say(say_please=False):
#    msg = "Can you buy me a beer?"
#    return msg, say_please
#
#
#print say()  # Can you buy me a beer?
#print say(say_please=True)  # Can you buy me a beer? Please! I am poor :(
#
#
##print ( dir(sys) )

#
#
#
#dedah = lambda z: print(z)
#
#
#def takesAlambda (lmb,r) :
#    lmb(r)
#    
#
###takesAlambda(dedah,15)
#
#def create_adder(x):
#    def adder(y):
#        return x + y
#    return adder
#
#add_10 = create_adder(10)
#
#tardar = []
#tardar = list(filter(lambda x: x > 5, [3, 4, 5, 6, 7]))
#
#print ( tardar )
#
#
#dobang = [add_10(i) for i in [1, 2, 3]]
#
##print ( dobang ) 
#





#
#def myprint(msg):
#    print (msg)
#
#f_list = [ myprint ]
#
#f_list[0]('hi')
#

#
#
#def retfunc (x):
#    def blah (y):
#        print (y,x)
#    return blah
#
#
#karl = retfunc(10)
#
#karl(6)
#
#map( karl, [4,66,2])
#







"""
def blah (**a):
    print (a)


a=7
b=5

blah(a=1,b=3)


b,a = a,b
print ( a , b )

hsh = {
    "dog" : "fido",
    "cat" : "hessles",
}

#kdk = {}

#kdk["tardar"]=hsh

#print ( kdk["tardar"]["cat"] )

gk = "dogaaaaa"
gk = "dog"

#print ( gk in hsh )


try:
    #print ( "%s == %s " % ( gk , hsh[gk] ) )
    print ( "%s " % hsh[gk] )
    #raise IndexError("its an ind-err")
except KeyError as e:
    print ( "%s is not a valid index on hsh" % gk )
except:
    print ( "unexpect except ", sys.exc_info()[0] )
else:
    print ("ALL GOOOOOOD !")


#if hsh.get(gk) :
#    print ( " we can get %s" % gk )
#else :
#    print ( " we can NOT get %s" % gk )
#

#hsh.setdefault(gk, "deeeeeeefaulllllt")


print ( hsh.get(gk, "default for %s" % gk ))




tup = ( 3,10,11,999,1,56,39392,1024,200,42 )


#print ( tup[2:8] )


print ( tup[::-1] + tup )

e = 5
d = 10

print ( e , d )


e , d = d , e


print ( e , d )



#ks = set ([1,2,2,2,2,2,2,3])

ka = [1, 2,2,2,2,2,2,2,2,3,3,3,3,4]
#ks = {1, 2,2,2,2,2,2,2,2,3,3,3,3,4}

ks = set(ka)

print (ks)

ks.add(7)
ks.add(2)

print (ks, " length =", len(ks) )

print (ka, " length =", len(ka) )




for i in range(100,5,-3) :
    print ( i )


"""





