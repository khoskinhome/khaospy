#!/usr/bin/python


x = [1, 2, 3]
y = [4, 5, 6]
zipped = zip(x, y,x)
print zipped

x2, y2, z2 = zip(*zipped)


print x2
print y2

