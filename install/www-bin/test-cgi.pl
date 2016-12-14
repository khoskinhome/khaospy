#!/usr/bin/perl
use strict;
use warnings;
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
