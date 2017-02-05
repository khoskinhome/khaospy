package AnyEvent::MQTT::Simple;
use strict; use warnings;

our $VERSION = '0.01';

use Carp qw(confess);
use Data::Dumper;
use AnyEvent;
use Net::MQTT::Constants;
use Net::MQTT::Message;
use IO::Select;
use IO::Socket::INET;
use Time::HiRes qw(usleep);

sub true  {1}
sub false {0}
sub SYSREAD_BYTES {2048}
sub TIMEOUT { 20 } # IO socket timeout.

sub KEEP_ALIVE_TIMER { 20 }
# TODO keep alive timer needs to ping the mqtt broker.
# in an AnyEvent timer.

sub SELECT_TIMEOUT { 0.02 }

sub RECONNECT_ATTEMPTS { 4 }

sub RECONNECT_USLEEP { 10000 };

sub new {
    my ($pkg, %p) = @_;
    my $self = bless {
        socket              => undef,
        reconnect           => true,
        reconnect_attempts  => RECONNECT_ATTEMPTS,
        reconnect_usleep    => RECONNECT_USLEEP,
        host                => '127.0.0.1',
        port                => '1883',
        timeout             => TIMEOUT, # IO socket timeout
        keep_alive_timer    => KEEP_ALIVE_TIMER,
        qos                 => MQTT_QOS_AT_MOST_ONCE,
        message_id          => 1,
        user_name           => undef,
        password            => undef,
        select_timeout      => SELECT_TIMEOUT,
        retain              => true,
        topics              => [], # for subscription only.
        pub_topic           => undef,
        topic               => undef,
            # 'topic' is a synonym for 'pub_topic', 'topic' takes precedence.
            # 'topic' will be used as the 'topic' to subscribe if 'topics' isn't defined

        client_id => undef,

#TODO this lot :
#        will_topic => undef,
#        will_qos => MQTT_QOS_AT_MOST_ONCE,
#        will_retain => 0,
#        will_message => '',
#        clean_session => 1,
#        write_queue => [],
#        inflight => {},

        %p,
    }, $pkg;

    return $self;
}

sub subscribe {
    my ( $self, %p ) = @_;

    map { $self->{$_} = $p{$_} } keys %p;

    $self->_mqtt_socket_sub_anyevent_connect(false);
}

sub publish {
    my ( $self, %p ) = @_;

    confess "Can't publish, no message"
        if ! $p{message};

    my $message = delete $p{message};

    map { $self->{$_} = $p{$_} } keys %p;

    my $topic = $self->{topic} || $self->{pub_topic};

    confess "Can't publish without a topic"
        if ! $topic;

    $self->_mqtt_socket_connect() if ! $self->{_socket};

    $self->_send_message(
        message_type => MQTT_PUBLISH,
        retain       => $self->{retain},
        message_id   => $self->_next_message_id(),
        topic        => $topic,
        message      => $message,
    );
}

sub _mqtt_socket_sub_anyevent_connect {
    my ($self, $force_reconnect) = @_;

    $self->_mqtt_socket_connect()
        if $force_reconnect || ! $self->{_socket};

    $self->_send_message(
        message_type => MQTT_SUBSCRIBE,
        message_id => $self->_next_message_id,
        topics     => $self->_topics,
    );

    $self->anyevent_reg();
}

sub _mqtt_socket_connect {
    my ($self) = @_;

    delete $self->{_socket};

    $self->{_socket} = IO::Socket::INET->new(
        PeerAddr => $self->{host}.':'.$self->{port},
        Timeout  => $self->{timeout},
    ) or $self->_fatal("Socket connect failed: $!");

    my @connect = (
        message_type     => MQTT_CONNECT,
        keep_alive_timer => $self->{keep_alive_timer},
        user_name        => $self->{user_name},
        password         => $self->{password}
    );

    push @connect, client_id => $self->{client_id}
        if ( defined $self->{client_id} );

    $self->_send_message( @connect );

#TODO hmmm , does this need to do more than this ?
    my $msg = $self->_read_message or $self->_fatal("No ConnAck");
}

sub anyevent_reg {
    my ($self) = @_;

    $self->_fatal("callback not defined / not a code-ref")
        if ref $self->{callback} ne 'CODE';

    delete $self->{_anyevent};

    $self->{_anyevent} = AnyEvent->io(
        fh   => $self->{_socket},
        poll => "r",
        cb   => sub {
            my $msg = $self->_read_message();
            $self->{callback}->($msg) if $msg;
        },
    );

    # TODO  if there's a keep_aliver_timer,
    # here we need an AnyEvent timer doing the mqtt pinging.



}

sub _reconnect {
    my ( $self ) = @_;

    $self->_fatal("Can't read/write to Socket (no reconnect) ")
        if ! $self->{reconnect};

    $self->{_attempted_reconnects}++;

    $self->_fatal("Can't reconnect to Socket, exceeded permitted attempts")
        if $self->{_attempted_reconnects} > $self->{reconnect_attempts};

    usleep $self->{reconnect_usleep};

    if ($self->{_anyevent} ){
        $self->_mqtt_socket_sub_anyevent_connect(true);
    } else {
        $self->_mqtt_socket_connect();
    }
}

sub _send_message {
    my $self = shift;

    my $msg = Net::MQTT::Message->new(@_);

    my $select = IO::Select->new($self->{_socket});

    unless ( $select->can_write($self->{select_timeout})){
        $self->reconnect;
        $self->_send_message(@_);
        return;
    };

    $msg = $msg->bytes;
    syswrite $self->{_socket}, $msg, length $msg;
    $self->{_attempted_reconnects} = 0;
}

sub _read_message {
    my ( $self ) = @_;

    my $buffer = '';
    my $select = IO::Select->new($self->{_socket});

    $select->can_read($self->{select_timeout}) || return;

    my $bytes =
        sysread $self->{_socket}, $buffer, SYSREAD_BYTES, length $buffer;

    unless ( $bytes ) {
        if ( defined $bytes ){
            if ($self->{reconnect}){
                warn "Socket closed gracefully, attempt reconnect ...\n";
                $self->_reconnect();
                return;
            }
            $self->_fatal("Socket closed gracefully");
        } else {
            $self->_fatal("Socket closed ERROR");
        }
    }

    $self->{_attempted_reconnects} = 0;

    my $mqtt = Net::MQTT::Message->new_from_bytes($buffer, 1);
    return $mqtt if (defined $mqtt);

    return;
}

sub _next_message_id {
    my $self = shift;
    my $res  = $self->{message_id};
    $self->{message_id}++;
    return $self->{message_id} %= 65536;
}

sub _topics { # only called for "subscription" Messages.
    my ($self) = @_;

    # topics is only for subscriptions
    # topic is for publish OR subscriptions.
    # topic will only be used for subscriptions if topics is not available.

    $self->{topics} = [ $self->{topics} ]
        if ref $self->{topics} ne 'ARRAY' && $self->{topics};

    $self->_fatal("no subscription topics defined")
        if ! @{$self->{topics}} && ! $self->{topic};

    $self->{topics} = [ $self->{topic} ]
        if $self->{topic} && ! @{$self->{topics}};

    return [ map { [ $_ => $self->{qos} ] } @{$self->{topics}} ]
}

sub DESTROY {
  my ( $self ) = @_ ;

  delete $self->{_socket};
  delete $self->{_anyevent};

}

sub _fatal {
    my ($self, $error) = @_;
    $self->DESTROY;
    confess "$error\n";
}

=head1 NAME

AnyEvent::MQTT::Simple - The great new AnyEvent::MQTT::Simple!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use AnyEvent::MQTT::Simple;

    my $foo = AnyEvent::MQTT::Simple->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Karl Hoskin, C<< <karl at khoskin.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-mqtt-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-MQTT-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::MQTT::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-MQTT-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-MQTT-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-MQTT-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-MQTT-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Karl Hoskin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
