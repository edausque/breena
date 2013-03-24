package Plugins::Google;
use strict qw(subs vars refs);
use warnings;
use Switch;
use POSIX qw(strftime);
use POE;
use POE::Component::IRC::Plugin qw( :ALL );
use LWP::Simple;
use JSON;
use Data::Dumper;

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

sub search {
  my ($query) = @_;
  my $google_json = get("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&safe=off&gl=fr&hl=fr&q=$query");
  my $google = from_json($google_json);
  if($google->{'responseStatus'} == 200) {
    my $result = $google->{'responseData'}->{'results'}[0];
    if(defined $result) {
      return $result->{'titleNoFormatting'} . " - " . $result->{'unescapedUrl'};
    } else {
      return "No results.";
    }
  } else {
    return $google->{'responseStatus'} . ": " . $google->{'responseDetails'};
  }
}

sub S_public {
  my ($self, $irc) = splice @_, 0, 2;

  # Parameters are passed as scalar-refs including arrayrefs.
  my ($who)    = (split /!/, ${$_[0]})[0];
  my ($channel) = ${$_[1]}->[0];
  my ($msg)     = ${$_[2]};

  if ($msg =~ /^\.(g|w|wiki|mat|ldlc|gh)\s(.+)$/) {
    my ($dest,$query) = ($1,$2);
    $query =~ s/\s/%20/g;
    my $prefix = "";
    switch($dest) {
      case "w"    { $prefix = "site:fr.wiktionary.org "; }
      case "wiki" { $prefix = "site:fr.wikipedia.org "; }
      case "mat"  { $prefix = "site:www.materiel.net "; }
      case "ldlc" { $prefix = "site:www.ldlc.com "; }
      case "gh"   { $prefix = "site:github.com "; }
    }
    $query = $prefix . $query;
    my $result = search($query);
    $irc->yield(privmsg => $channel => "$result");
    return PCI_EAT_PLUGIN;    # We don't want other plugins to process this
  }
  return PCI_EAT_NONE; # Default action is to allow other plugins to process it.
}
1;
