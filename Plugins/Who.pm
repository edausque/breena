package Plugins::Who;
use strict qw(subs vars refs);
use warnings;
use POE;
use POE::Component::IRC::Plugin qw( :ALL );
use Config::Simple;

my ($dirpath) = (__FILE__ =~ m{^(.*/)?.*}s);
my $conf_file = "${dirpath}../breena.conf";

my $conf = new Config::Simple("$conf_file") or die "impossible de trouver $conf_file";
my $conf_nick = $conf->param("nick");

# Plugin object constructor
sub new {
  my ($package) = shift;
  return bless {}, $package;
}

sub PCI_register {
  my ($self, $irc) = splice @_, 0, 2;
  $irc->plugin_register($self, 'SERVER', qw(public));
  return 1;
}

sub PCI_unregister {
  return 1;
}

sub S_public {
  my ($self, $irc) = splice @_, 0, 2;

  # Parameters are passed as scalar-refs including arrayrefs.
  my ($who)    = (split /!/, ${$_[0]})[0];
  my ($channel) = ${$_[1]}->[0];
  my ($msg)     = ${$_[2]};

  if ($msg =~ /^$conf_nick.*qui es-tu\s*\?/) {
    $irc->yield(privmsg => $channel => "Je suis un bot ecrit en Perl qui sait faire plein de choses !");
    $irc->yield(privmsg => $channel => "Mes sources sont disponibles sur GitHub: https://github.com/MiLk/Mileina");
    return PCI_EAT_PLUGIN;    # We don't want other plugins to process this
  }
  return PCI_EAT_NONE; # Default action is to allow other plugins to process it.
}

