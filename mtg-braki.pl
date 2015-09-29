#!/usr/bin/env perl
use Getopt::Std;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use mtg;

sub read_base {

  my %lst;

  my $baza = Archive::Zip->new();
  unless ( $baza->read( '../../mtg.tc' ) == AZ_OK ) {
       die 'read error';
  }
  foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
      $_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
      $lst{ $1 } = "1";
  }
  return %lst;
} # sub read_base

getopt('n', \%opts);

if (!$opts{'n'}) { die "-n - search by expantion.\n";}

#  %lista = {};
 %lista = mtg::build_checklist $opts{'n'};

      $,="\n";
      print sort(values %lista);


%karty = read_base;

#   $,="\n";
#   print (keys %karty)."\n";

@brak;

$j=0;

foreach $i (keys %lista) {
   unless (exists $karty{ $i }) {
       print $lista{ $i }."\n";
       $j++;
   }
}

print $j." cards missing.\n";