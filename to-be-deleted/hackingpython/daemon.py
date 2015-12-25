#!/usr/bin/python
import daemon

from spam import do_main_program

with daemon.DaemonContext():
    do_main_program()



