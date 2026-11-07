#!/usr/bin/perl -pi
s/^(\s*)repo = ("[^"]+"),/$1$2,/;
s/\blua_source = function/config = function/;
s/\blua_add = function/init = function/;
s/^(\s*)on_cmd =/$1cmd =/; s/^(\s*)on_event =/$1event =/; s/^(\s*)on_ft =/$1ft =/;
s/^(\s*)depends =/$1dependencies =/; s/^(\s*)rev =/$1branch =/;
s/extAttrs = \{ installerBuild = ("[^"]+") \}/build = $1/;
if (/^(\s*)on_map = \{(.*)\},\s*$/) {
  my ($ind,$body)=($1,$2); my %m; 
  while ($body =~ /(\w+) = \{([^}]*)\}/g) { my ($modes,$l)=($1,$2); for my $k ($l =~ /"([^"]+)"/g) { $m{$k}{$_}=1 for split //,$modes } }
  my @e = map { my $k=$_; my $ms=join(", ",map {"\"$_\""} sort keys %{$m{$k}}); "{ \"$k\", mode = { $ms } }" } sort keys %m;
  $_ = "${ind}keys = { ".join(", ",@e)." },\n";
}
