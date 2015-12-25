#!/bin/bash

# alias hackitdaemon='nohup sudo /opt/k-ha-os/amelia-light/hackit-daemon.pl  & '
alias khaospy-amelia-hackit-daemon='nohup sudo /opt/khaospy/bin/khaospy-amelia-hackit-daemon.pl  & '

alias khaospy-rad-daemon='nohup sudo /opt/khaospy/bin/khaospy-orvibo-s20-radiator.pl &'

alias khaospy-one-wired-sender='nohup sudo modprobe w1-gpio w1-therm; /opt/khaospy/bin/khaospy-one-wired-sender.py &'

alias khaospy-one-wired-receiver-piloft='nohup sudo /opt/khaospy/bin/khaospy-one-wired-receiver.py --host piloft &'
alias khaospy-one-wired-receiver-pioldwifi='nohup sudo /opt/khaospy/bin/khaospy-one-wired-receiver.py --host pioldwifi &'

alias khaospy-ps='ps afux | egrep "(one-wired|khaospy|amelia)" | grep -v grep | grep -v rrdcreategraph'

export PATH="$PATH:/opt/khaospy/bin"

