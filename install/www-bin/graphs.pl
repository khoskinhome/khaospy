#!/usr/bin/perl
use strict;
use warnings;

#print "Content-type: text/html\r\n\r\n";
#
#print "Hello there!<br />\nJust testing .<br />\n";
#
#for (my $i=0; $i<10; $i++) {
#    print $i."<br />";
#}
#
#

my $html = "Content-Type: text/html
<!DOCTYPE html>
<HTML>
<HEAD>
<TITLE>Hello World</TITLE>
</HEAD>
<BODY>
<H4>Hello World</H4>
<P>
Your IP Address is $ENV{REMOTE_ADDR}
<P>
<H5>Have a nice day</H5>
</BODY>
</HTML>";

print $html;
