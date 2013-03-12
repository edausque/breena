package Plugins::Man;
use strict qw(subs vars refs);
use warnings;
use POE;
use POE::Component::IRC::Plugin qw( :ALL );
use Config::Simple;

my ($dirpath) = (__FILE__ =~ m{^(.*/)?.*}s);

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

  if ($msg =~ /^man ([0-9]{1}) ([A-Za-z0-9-]+)/) {
    $irc->yield(privmsg => $channel => "http://linux.die.net/man/$1/$2");
    return PCI_EAT_PLUGIN;    # We don't want other plugins to process this
  }
  elsif ($msg =~ /^man \? ([A-Za-z0-9-]+)/) {
    $irc->yield(privmsg => $channel => "http://www.die.net/search/?q=$1&sa=Search&ie=ISO-8859-1&cx=partner-pub-5823754184406795%3A54htp1rtx5u&cof=FORID%3A9");
    return PCI_EAT_PLUGIN;    # We don't want other plugins to process this
  }
  elsif ($msg =~ /^man ([A-Za-z0-9-]+)/) {
    $irc->yield(privmsg => $channel => "http://www.unix.com/man-page/linux/0/$1");
    return PCI_EAT_PLUGIN;    # We don't want other plugins to process this
  }
  return PCI_EAT_NONE; # Default action is to allow other plugins to process it.
}

