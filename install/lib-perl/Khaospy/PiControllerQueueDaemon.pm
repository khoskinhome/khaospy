package Khaospy::PiControllerDaemon;
# http://stackoverflow.com/questions/6024003/why-doesnt-zeromq-work-on-localhost/8958414#8958414
# http://domm.plix.at/perl/2012_12_getting_started_with_zeromq_anyevent.html
# http://funcptr.net/2012/09/10/zeromq---edge-triggered-notification/

=pod


=cut

use warnings;

use Exporter qw/import/;
use Data::Dumper;
use Carp qw/croak/;
use JSON;
use Sys::Hostname;

use AnyEvent;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(
    ZMQ_RCVMORE
    ZMQ_SUBSCRIBE
    ZMQ_FD
    ZMQ_PUB
    ZMQ_PULL
);

use FindBin;
FindBin::again();
use lib "$FindBin::Bin/../lib-perl";

use zhelpers;

use Khaospy::Constants qw(
    $ZMQ_CONTEXT
    true false
    ON OFF STATUS
    $PI_CONTROLLER_QUEUE_DAEMON_SEND_PORT
    $PI_CONTROLLER_DAEMON_SEND_PORT
);

use Khaospy::Conf qw(
    get_controls_conf
    get_pi_controller_conf
);

use Khaospy::Utils qw( timestamp );

our @EXPORT_OK = qw( run_controller_daemon );

our $PUBLISH_STATUS_EVERY_SECS = 5;

my $JSON = JSON->new->allow_nonref;

our $VERBOSE;


