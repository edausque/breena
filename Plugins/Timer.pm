package Plugins::Timer;
use strict qw(subs vars refs);
use warnings;
use POE;
use POE::Component::IRC::Plugin qw( :ALL );

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

sub bot_timer {
  my ($self, $irc) = splice @_, 0, 2;
  $irc->yield(privmsg => $_[ARG3] => "$_[ARG1]: ding!$_[ARG0]")
}

sub S_public {
  my ($self, $irc) = splice @_, 0, 2;

  # Parameters are passed as scalar-refs including arrayrefs.
  my ($who)    = (split /!/, ${$_[0]})[0];
  my ($channel) = ${$_[1]}->[0];
  my ($msg)     = ${$_[2]};

  if ($msg =~ /^timer\s(\S*)\s*(.*?)$/) {
    my $seconds = $1;
    my $task = " $2";
    $seconds =~ s/[^mhd\d]//g; 
    $seconds =~ s/(\d+)(\w{1})(\d+)/$1$2+$3/g;
    $seconds =~ s/(\d+)(\w{1})(\d+)/$1$2+$3/g;
    $seconds =~ s/m/*60/g; 
    $seconds =~ s/h/*3600/g; 
    $seconds =~ s/d/*3600*24/g; 
    $seconds = eval($seconds);
    if($seconds =~ /^\d+$/) {
      $irc->yield(privmsg => $channel => "[timer added]$task ($seconds seconds)");
      $_[KERNEL]->delay_add(bot_timer => $seconds, $task, $who, $channel);
    } else {
      $irc->yield(privmsg => $channel => "$who, usage: t 1d2h42m10s [task]");
    }
    return PCI_EAT_PLUGIN;    # We don't want other plugins to process this
  }
  return PCI_EAT_NONE; # Default action is to allow other plugins to process it.
}

