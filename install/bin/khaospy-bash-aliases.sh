#!/bin/bash

# alias hackitdaemon='nohup sudo /opt/k-ha-os/amelia-light/hackit-daemon.pl  & '
alias khaospy-amelia-hackit-daemon='nohup sudo /opt/khaospy/bin/khaospy-amelia-hackit-daemon.pl  & '

alias khaospy-rad-daemon='nohup sudo /opt/khaospy/bin/khaospy-orvibo-s20-radiator.pl &'

alias khaospy-one-wired-sender='nohup sudo modprobe w1-gpio w1-therm; /opt/khaospy/bin/khaospy-one-wired-sender.py &'

alias khaospy-one-wired-receiver-piloft='nohup sudo /opt/khaospy/bin/khaospy-one-wired-receiver.py --host piloft &'
alias khaospy-one-wired-receiver-pioldwifi='nohup sudo /opt/khaospy/bin/khaospy-one-wired-receiver.py --host pioldwifi &'

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
alias cdkhaospylibperlt='cd /opt/khaospy/lib-perl-t/'

alias bashrc='. ~/.bashrc'
alias r='reset;unalias -a;. ~/.bashrc'

alias la='ls --color=auto -la'
alias lart='ls --color=auto -lart'
alias l1='ls --color=auto -1'

alias hg='history | grep -i'

alias s.reboot='sudo reboot'
alias s.shutdown='sudo shutdown'
alias s.crontab='sudo crontab'

alias khaospy-ps='ps afux | egrep "(one-wired|khaospy|amelia)" | grep -v grep | grep -v generate-rrd-graphs '
alias ps-khaospy='ps afux | egrep "(one-wired|khaospy|amelia)" | grep -v grep | grep -v generate-rrd-graphs '

alias kps.khaospy='sudo /opt/khaospy/bin/khaospy-ps.pl'
alias kps.khaospy.kill='sudo /opt/khaospy/bin/khaospy-ps.pl -k'
alias kdaemons_run='sudo /opt/khaospy/bin/khaospy-run-daemons.pl'
alias kzmq_subscribe='sudo /opt/khaospy/bin/khaospy-zmq-subscribe.pl'

alias kdboiler_d='sudo /opt/khaospy/bin/khaospy-boiler-daemon.pl'
alias kdpi_controls_d='sudo /opt/khaospy/bin/khaospy-pi-controls-d.pl'
alias kdother_controls_d='sudo /opt/khaospy/bin/khaospy-other-controls-d.pl'
alias kdcommand_queue_d='sudo /opt/khaospy/bin/khaospy-command-queue-d.pl'
alias kdone_wired_sender_d='sudo /opt/khaospy/bin/khaospy-one-wired-sender.py'
alias kdheating_d='sudo /opt/khaospy/bin/khaospy-heating-daemon.pl'

alias koperate_control='sudo /opt/khaospy/bin/khaospy-operate-control.pl'
alias kclive_conf_generate='sudo /opt/khaospy/bin/khaospy-live-conf-generate.pl'
alias kctest_conf_generate='sudo /opt/khaospy/bin/khaospy-test-conf-generate.pl'
alias ktests='/opt/khaospy/lib-perl-t/alltests.t; /opt/khaospy/bin/test-module-includes.pl'

cd /opt/khaospy/bin
