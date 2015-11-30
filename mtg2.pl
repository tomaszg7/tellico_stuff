#!/usr/bin/env perl
use Getopt::Std;

use mtg;

getopt('naN', \%opts);

if (!$opts{'n'} && !$opts{'a'} && !$opts{'N'}) { die "-n - search by name, -N - search by multiverseid, -a - search by artist.\n";}


if ($opts{'N'}) {
  if ($opts{'N'} =~ /\d+/ ) {
    print mtg::header;
    print mtg::entry $opts{'N'}, 0;
    print '<images>';
    print mtg::image $opts{'N'};
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
  
  @lista = mtg::search($sstr);
  
  #pozbycie sie duplikatow
  my %hash   = map { $_, 1 } @lista;
  @lista = keys %hash;
  
  #wybranie 10 pierwszych wynikow
  @l_tmp1=@lista[0..9];
  @l_tmp2=@l_tmp1;
  
  $i=0;
  
  print mtg::header;
  while ($n = shift @l_tmp1)
  {
    print mtg::entry $n, $i;
    $i++;
  }
  print '<images>';
  while ($n = shift @l_tmp2)
  {
    print mtg::image $n;
  }
  print '</images></collection></tellico>';
}

