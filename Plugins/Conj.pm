package Plugins::Conj;
use strict qw(subs vars refs);
use warnings;
use POE;
use POE::Component::IRC::Plugin qw( :ALL );
use Config::Simple;

my ($dirpath) = (__FILE__ =~ m{^(.*/)?.*}s);
my $conf_file = "${dirpath}../breena.conf";

my $conf = new Config::Simple("$conf_file") or die "impossible de trouver $conf_file";
my $conf_nick = $conf->param("nick");
my $conf_nickserv = $conf->param("nickserv");
my $conf_server = $conf->param("server");
my $conf_channel = $conf->param("channel");
my $conf_debug = $conf->param("debug");

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

  if ($msg =~ /^\.conj.*? (.*)/) {
    $irc->yield(privmsg => $channel => "http://www.vatefaireconjuguer.com/search?verb=$1");
    return PCI_EAT_PLUGIN;    # We don't want other plugins to process this
  }
  return PCI_EAT_NONE; # Default action is to allow other plugins to process it.
}

