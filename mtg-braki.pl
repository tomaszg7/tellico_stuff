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

  my $baza = Archive::Zip->new();
  unless ( $baza->read( '../mtg-liga2.tc' ) == AZ_OK ) {
       die 'read error';
  }
  foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
      $_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
      $lst{ $1 } = "1";
  }
  
  return %lst;
} # sub read_base

getopts('n:q', \%opts);

if (!$opts{'n'}) { die "-n - search by expansion, -q - print only summary.\n";}

my $exp = $opts{'n'};
if (%mtg::expansions{ $exp }) {$exp = %mtg::expansions{ $exp }};

%lista = mtg::build_checklist $exp;

#       $,="\n";
#       print sort(values %lista);

if (keys( %lista) == 0) { die "Wrong expansion name.\n"; }

%karty = read_base;

#   $,="\n";
#   print (keys %karty)."\n";

@brak;

$j=0;

@out;

foreach $i (keys %lista) {
   unless (exists $karty{ $i }) {
       push @out, $lista{ $i };
       $j++;
   }
}

unless ($opts{'q'}) { print "$_\n" for sort(@out); };

print $j." cards missing, ".keys( %lista)." cards total, ".int((1-$j/keys(%lista))*100)."\% complete.\n";