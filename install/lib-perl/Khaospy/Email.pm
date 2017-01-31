package Khaospy::Email;
use strict;
use warnings;
use 5.14.2;

use Exporter qw/import/;
our @EXPORT_OK = qw( send_email );

use Try::Tiny;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;

use Khaospy::Conf qw( get_email_conf );

use Khaospy::Utils qw(get_hashval);
use Khaospy::Log qw(
    klogerror
);

use Khaospy::Constants qw(
    true false
);

# only currently sends stuff to gmail. hmmm.

sub send_email {
    my ($p) = @_;

    my $email_cfg;
    try {
        $email_cfg = get_email_conf();
    } catch {
        klogerror("Error getting email config\ncouldn't send email : ", $p, undef, true );
    };
    return if ! $email_cfg;

    my $username = get_hashval($email_cfg,'username');

    my $email = Email::Simple->create(
        header => [
            From    => $username,
            To      => get_hashval($p,'to'),
            Subject => get_hashval($p,'subject'),
        ],
        body => get_hashval($p,'body'),
    );

    my $sender = Email::Send->new(
        {   mailer      => 'Gmail',
            mailer_args => [
                username => $username,
                password => get_hashval($email_cfg,'password'),
            ]
        }
    );

    eval { $sender->send($email) };
    klogerror "Error sending email: $@" if $@;
}
