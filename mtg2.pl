#!/usr/bin/env perl
use Getopt::Std;

use mtg;

getopt('naN', \%opts);

if (!$opts{'n'} && !$opts{'a'} && !$opts{'N'}) { die "-n - search by name, -N - search by multiverseid, -a - search by artist.\n";}


if ($opts{'N'}) {
  if ($opts{'N'} =~ /\d+/ ) {
    print mtg::header;
    $entry = mtg::get_entry $opts{'N'};
    print mtg::print_entry ($entry, 0);
    print '<images>';
    print mtg::image $entry->{image1};
    if ($entry->{image2})  {print mtg::image $entry->{image2};}
    print '</images></collection></tellico>';
  }
  else { die "-N value is not a number.\n"}
}
elsif ($opts{'n'} || $opts{'a'} ) {
  if ($opts{'n'}) {
    $sstr = $opts{'n'};
    $sstr =~ s/\s+/]+[/g;
    $sstr = "name=+[".$sstr."]";
  }
  else {
    $sstr = $opts{'a'};
    $sstr =~ s/\s+/]+[/g;
    $sstr = "artist=+[".$sstr."]";
  }
  
  %wyniki = mtg::search($sstr);
  @lista = keys %wyniki;

  $i=0;
  my @images;
  
  print mtg::header;
  while (($n = shift @lista) && (i < 10))
  {
    $entry = mtg::get_entry $n;
    print mtg::print_entry ($entry, $i);
    push @images, $entry->{image1};
    if ($entry->{image2})  {push @images, $entry->{image2};}
    $i++;
  }
  print '<images>';

  #pozbycie sie duplikatow
  %hash   = map { $_, 1 } @images;
  @images = keys %hash;

  while ($n = shift @images)
  {
    print mtg::image $n;
  }
  print '</images></collection></tellico>';
}

