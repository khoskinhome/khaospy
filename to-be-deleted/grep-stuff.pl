#!/usr/bin/perl

my $search = $ARGV[0];


for my $type ( qw(
    orvibos20
    onewire-thermometer

    pi-gpio-relay-manual
    pi-gpio-relay
    pi-gpio-switch

    pi-mcp23017-relay-manual
    pi-mcp23017-relay
    pi-mcp23017-switch

    mac-switch
    ping-switch

)){

    system ("git grep -nH \"'$type'\" | grep -v controls\\-relays\\-switches\\-sensors\\-conf.txt ");
    system ("git grep -nH '\"$type\"'| grep -v controls\\-relays\\-switches\\-sensors\\-conf.txt ");
    system ("git grep -nH '($type)'| grep -v controls\\-relays\\-switches\\-sensors\\-conf.txt ");
    system ("git grep -nH '{$type}'| grep -v controls\\-relays\\-switches\\-sensors\\-conf.txt ");

}
##git grep -nH \'"$1"\'
#git grep -nH '\"$1\"'
