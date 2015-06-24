#!/usr/bin/python


from time import sleep

def fibonacci(limit):
    a, b, c = 0, 1, 0
    while a < limit :
        yield a
        a = a + 1
        yield a
        a = a + 1
        yield a
        a = a + 1
        yield a
        a = a + 1
        yield a
        a = a + 1
        sleep(1)







#    while 1 == 1 :
#        yield a
#        a, b, c = b, a+b, c+1
 
for number in fibonacci(100):  # The generator constructs an iterator
    print(number)


