#!/usr/bin/python

"""
khaospy-run-servers.py

By Karl Hoskin 2015-12-25

this script should be cron-ed to run every few minutes.

It checks that all the khaospy daemons are running on the host

The config is got from /opt/khaospy/conf/daemon-runner.json

"""

import zmq
import sys
import os
import os.path
import time
import re
import json
from pprint import pprint

##!/usr/bin/perl
#use strict;
#use warnings;
#use 5.14.2;
#
#use JSON;
#
#my $khaospy_root = "/opt/khaospy"
#
#my $conf_file="$khaospy_root/conf/daemon-runner.json";
#

