#!/usr/bin/python

y = 7

y+=1


# Using the generator pattern (an iterable)
class firstn(object):
    def __init__(self, n):
        self.n = n
        self.num, self.nums = 0, []

    def __iter__(self):
        return self

    # Python 3 compatibility
    def __next__(self):
        return self.next()

    def next(self):
        if self.num < self.n:
            cur, self.num = self.num, self.num+1
            return cur
        else:
            raise StopIteration()

sum_of_first_n = sum(firstn(10))

print sum_of_first_n

x = firstn(10)

print x.__iter__()

print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.__iter__()
print x.next()
print x.next()

#print sum_of_first_n
