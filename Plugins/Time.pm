package Plugins::Time;
use strict qw(subs vars refs);
use warnings;
use Switch;
use POSIX qw(strftime);
use POE;
use POE::Component::IRC::Plugin qw( :ALL );
use Config::Simple;
use LWP::Simple;
use JSON;
use Data::Dumper;

my ($dirpath) = (__FILE__ =~ m{^(.*/)?.*}s);
my $conf_file = "${dirpath}../breena.conf";

my $conf = new Config::Simple("$conf_file") or die "impossible de trouver $conf_file";
my $conf_google_api = $conf->param("google-api");

# Plugin object constructor
sub new {
  my ($package) = shift;
  my $self = bless {@_}, $package;
  $self->{SESSION_ID} = POE::Session->create(object_states => [$self => [qw(_start)],],)->ID();
  return $self;
}

sub PCI_register {
  my ($self, $irc) = splice @_, 0, 2;
  $self->{irc} = $irc;
  $irc->plugin_register($self, 'SERVER', qw(public));
  return 1;
}

sub PCI_unregister {
  my ($self, $irc) = splice @_, 0, 2;
  delete $self->{irc};

  # Plugin is dying make sure our POE session does as well.
  $poe_kernel->refcount_decrement($self->{SESSION_ID}, __PACKAGE__);
  return 1;
}

sub _start {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $self->{SESSION_ID} = $_[SESSION]->ID();

  # Make sure our POE session stays around. Could use aliases but that is so messy :)
  $kernel->refcount_increment($self->{SESSION_ID}, __PACKAGE__);
}

sub S_public {
  my ($self, $irc) = splice @_, 0, 2;

  # Parameters are passed as scalar-refs including arrayrefs.
  my ($who)    = (split /!/, ${$_[0]})[0];
  my ($channel) = ${$_[1]}->[0];
  my ($msg)     = ${$_[2]};

  if ($msg =~ /^time (.+)$/) {
    my $address = $1;
    $address =~ s/\s//g;
    my $now_string = "Data not found.";
    my $geocode_json = get("https://maps.googleapis.com/maps/api/geocode/json?address=".$address."&sensor=false&language=fr&region=fr&api=".$conf_google_api);
    my $geocode = from_json($geocode_json);
    if($geocode->{'status'} eq 'OK') {
      my $loc = $geocode->{'results'}[0]->{'geometry'}->{'location'};
      my $req = "https://maps.googleapis.com/maps/api/timezone/json?location=".$loc->{'lat'}.",".$loc->{'lng'}."&timestamp=".strftime("%s",gmtime())."&sensor=false&language=fr&api=".$conf_google_api;
      my $timezone_json = get($req);
      my $timezone = from_json($timezone_json);
      if($timezone->{'status'} eq 'OK') {
        $now_string = strftime "%a %b %e %H:%M:%S %Y", gmtime(time + $timezone->{'rawOffset'} + $timezone->{'dstOffset'});
        $now_string = $timezone->{'timeZoneId'} . ": " . $now_string;
      } else {
        $now_string = $timezone->{'status'};
      }
    } else {
      $now_string = $geocode->{'status'};
    }
    $irc->yield(privmsg => $channel => "$now_string ($address)");
    return PCI_EAT_PLUGIN;    # We don't want other plugins to process this
  }
  return PCI_EAT_NONE; # Default action is to allow other plugins to process it.
}

