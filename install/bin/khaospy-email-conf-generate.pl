#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use Khaospy::Utils qw(burp);
use Khaospy::Constants qw(
    $JSON
    $EMAIL_CONF_FULLPATH
);

# script to generate email conf. change values below :

my $EMAIL_USERNAME = 'some-user@gmail.com';
my $EMAIL_PASSWORD = 'a-password';

write_out_email_conf();

sub write_out_email_conf {

    print "Generating $EMAIL_CONF_FULLPATH\n";

    burp ( $EMAIL_CONF_FULLPATH,

           $JSON->pretty->encode({
                username => $EMAIL_USERNAME,
                password => $EMAIL_PASSWORD,
            })
    );

    my $mode = 0600;
    chmod $mode, $EMAIL_CONF_FULLPATH;
}
