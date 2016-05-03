#!/usr/bin/python

import rrdtool

databaseFile = "/home/khoskin/temperature-monitor/rrddb/temperature.rrd"
MIN_TEMP = -50
ERROR_TEMP = -999.99

rrds_to_filename = {
  "a" : "/sys/bus/w1/devices/28-011465167eff/w1_slave",
  "b" : "/sys/bus/w1/devices/28-021463277cff/w1_slave",
  "c" : "/sys/bus/w1/devices/28-02146329ceff/w1_slave",
  "d" : "/sys/bus/w1/devices/28-0214632d16ff/w1_slave",
  "e" : "/sys/bus/w1/devices/28-021463423bff/w1_slave",
}

def read_temperature(file):
  tfile = open(file)
  text = tfile.read()
  tfile.close()
  lines = text.split("\n")
  if lines[0].find("YES") > 0:
    temp = float((lines[1].split(" ")[9])[2:])
    temp /= 1000
    return temp
  return ERROR_TEMP

def read_all():
  template = ""
  update = "N:"
  for rrd in rrds_to_filename:
    template += "%s:" % rrd
    temp = read_temperature(rrds_to_filename[rrd])
    update += "%f:" % temp
  update = update[:-1]
  template = template[:-1]
  rrdtool.update(databaseFile, "--template", template, update)
  print databaseFile
  print template
  print update

read_all()

