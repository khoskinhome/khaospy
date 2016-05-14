#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Email qw (
    send_email
);

send_email({
    to => 'karl.hoskin@googlemail.com',
    subject => "blah blah",
    body => "some crap  more kerap !",
});
