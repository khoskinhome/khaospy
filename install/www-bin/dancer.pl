#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Dancer2;
use Dancer2::Plugin::Database;

get '/hello/:name' => sub {
    return "Why, hello there " . params->{name};
};

get '/env' => sub {

    my $out = "";
    for my $k ( sort keys %ENV ) {
        $out .= "$k => ".$ENV{$k}."\n";
    }

    $out .= config->{appdir}."\n";

    return "<pre>$out</pre>";
};

get '/' => sub {

    my $sth = database->prepare("select * from users");


    return template 'test.tt', {
        test => "this is a test",

    };
};


dance;

##!/usr/bin/perl
#use strict;
#use warnings;
#my $html = "Content-Type: text/html
#
#<HTML>
#<HEAD>
#<TITLE>Hello World</TITLE>
#</HEAD>
#<BODY>
#<H4>Hello World</H4>
#<P>
#Your IP Address is $ENV{REMOTE_ADDR}
#
#<P>
#<H5>Have a nice day</H5>
#</BODY>
#</HTML>";
#
#print $html;
#
#
