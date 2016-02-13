#!/bin/bash

# alias hackitdaemon='nohup sudo /opt/k-ha-os/amelia-light/hackit-daemon.pl  & '
alias khaospy-amelia-hackit-daemon='nohup sudo /opt/khaospy/bin/khaospy-amelia-hackit-daemon.pl  & '

alias khaospy-rad-daemon='nohup sudo /opt/khaospy/bin/khaospy-orvibo-s20-radiator.pl &'

alias khaospy-one-wired-sender='nohup sudo modprobe w1-gpio w1-therm; /opt/khaospy/bin/khaospy-one-wired-sender.py &'

alias khaospy-one-wired-receiver-piloft='nohup sudo /opt/khaospy/bin/khaospy-one-wired-receiver.py --host piloft &'
alias khaospy-one-wired-receiver-pioldwifi='nohup sudo /opt/khaospy/bin/khaospy-one-wired-receiver.py --host pioldwifi &'

alias khaospy-ps='ps afux | egrep "(one-wired|khaospy|amelia)" | grep -v grep | grep -v generate-rrd-graphs '
alias ps-khaospy='ps afux | egrep "(one-wired|khaospy|amelia)" | grep -v grep | grep -v generate-rrd-graphs '

export PATH="$PATH:/opt/khaospy/bin:/opt/khaospy/bin/helper"

alias cdkhaospy='cd /opt/khaospy/'
alias cdkhaospybin='cd /opt/khaospy/bin/'
alias cdkhaospyconf='cd /opt/khaospy/conf/'
alias cdkhaospydocs='cd /opt/khaospy/docs/'
alias cdkhaospydownloads='cd /opt/khaospy/downloads/'
alias cdkhaospyhackingpython='cd /opt/khaospy/hackingpython/'
alias cdkhaospywww='cd /opt/khaospy/www/'
alias cdkhaospywwwbin='cd /opt/khaospy/www-bin/'
alias cdkhaospypid='cd /opt/khaospy/pid/'
alias cdkhaospylog='cd /opt/khaospy/log/'

alias bashrc='. ~/.bashrc'

alias la='ls --color=auto -la'
alias lart='ls --color=auto -lart'
alias l1='ls --color=auto -1'

alias s.reboot='sudo reboot'
alias s.shutdown='sudo shutdown'
alias s.khaospy_zmq_subscribe='sudo /opt/khaospy/bin/khaospy-zmq-subscribe.pl'
alias s.khaospy_controller_daemon='sudo /opt/khaospy/bin/khaospy-controller-daemon.pl'
alias s.khaospy_controller_queue_d='sudo /opt/khaospy/bin/khaospy-controller-queue-d.pl'
alias s.khaospy_operate_control='sudo /opt/khaospy/bin/khaospy-operate-control.pl'

cd /opt/khaospy/bin
