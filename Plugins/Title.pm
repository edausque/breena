package Plugins::Title;
use strict qw(subs vars refs);
use warnings;
use POE;
use POE::Component::IRC::Plugin qw( :ALL );
use URI::Find;
use LWP::UserAgent;

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

  my $ua = LWP::UserAgent->new(timeout => 5);
  my $finder = URI::Find->new(sub {
    my($uri, $orig_uri) = @_;
    my $response = $ua->get($uri);
    if ($response->is_success) {
      $irc->yield(privmsg => $channel => $response->title());
    }
    else {
      $irc->yield(privmsg => $channel => $response->status_line);
    }
  });
  $finder->find(\$msg);
  return PCI_EAT_NONE; # Default action is to allow other plugins to process it.
}
1;
