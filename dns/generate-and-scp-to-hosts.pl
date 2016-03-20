#!/usr/bin/perl
use strict;
use warnings;
use 5.14.2;
use File::Basename;

my $USER='root';
my $PI_ETC_BIND_DIR='/etc/bind/';

my $TEMPLATE_DIR  = './template/';
my $TEMPLATE_REPLACE_PATTERN ='<PIHOSTNAME>';

my $GENERATED_DIR = './generated/';
my $INIT_D_BIND_RESTART = 'sudo /etc/init.d/bind9 restart';

# sanity checks to make sure we're in the correct place :
my $basename = basename($0);
die "can't find $basename you mush be running this script from the wrong dir"
    if ( ! -f $basename );

for my $pihost ( qw/piloft  piserver/ ){
    say "DNS files for $pihost";
    generate_files($pihost);
    scp_files($pihost);
}

sub generate_files {
    my ($pihost) = @_;

    for my $filename ( <"$TEMPLATE_DIR/*"> ){
        say "    $filename";
        my $filecontents = slurp($filename);
        $filecontents =~ s/$TEMPLATE_REPLACE_PATTERN/$pihost/g;
        burp($GENERATED_DIR.fileparse($filename), $filecontents);
    }
}

sub scp_files {
    my ($pihost) = @_;

    for my $filename ( <"$GENERATED_DIR/*"> ){
        system ("scp $filename $USER\@$pihost:$PI_ETC_BIND_DIR");
    }

    system("ssh $USER\@$pihost '$INIT_D_BIND_RESTART' ");
}

sub slurp {
    my ( $file ) = @_;
    open( my $fh, $file ) or die "Can't open file $file $!\n";
    my $text = do { local( $/ ) ; <$fh> } ;
    return $text;
}

sub burp {
    my( $file_name ) = shift ;
    open( my $fh, ">" , $file_name ) || die "Can't create $file_name $!\n" ;
    print $fh @_ ;
}

