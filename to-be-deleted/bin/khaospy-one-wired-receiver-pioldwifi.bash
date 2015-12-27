#!/bin/bash

# This script is needed because its easier to get the "daemon" program
# ( sudo apt-get install daemon )
# to have a single script to call without parameters and get it to create the PID.

# sudo modprobe w1-gpio w1-therm
/opt/khaospy/bin/khaospy-one-wired-receiver.py --host pioldwifi


