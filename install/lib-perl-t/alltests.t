#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;

use File::Basename;
my $alltests_filename = basename($0);

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl/";

use Khaospy::Constants qw(
    $LIB_PERL
    $LIB_PERL_T
);


chdir ($LIB_PERL_T) or die "Can't cd to $LIB_PERL_T";

for my $t_file (<*.t>){
    next if $t_file eq $alltests_filename;

    say '';
    say $t_file;

    my $result ;

    system("perl $t_file");


}
