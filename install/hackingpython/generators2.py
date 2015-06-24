#!/usr/bin/python

def countdown(n):
    print "Counting down from", n
    while n > 0:
        print n
        yield n
        n -= 1


x = countdown(10)

x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()
x.next()

x.next()

x.next()

x.next()








