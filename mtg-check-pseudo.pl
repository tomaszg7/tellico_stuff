#!/usr/bin/env perl
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

  $baza = Archive::Zip->new();
  unless ( $baza->read( '../mtg-liga3.tc' ) == AZ_OK ) {
       die 'read error';
  }
  foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
      $_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
      $lst{ $1 } = "1";
  }

  $baza = Archive::Zip->new();
  unless ( $baza->read( '../mtg-agn.tc' ) == AZ_OK ) {
       die 'read error';
  }
  foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
      $_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
      $lst{ $1 } = "1";
  }
  
  return %lst;
} # sub read_base

%karty = read_base;

foreach $i (keys %mtg_pseudo::pseudo) {
   if (exists $karty{ $i }) {
       print "$i $lista{ $i }\n";
   }
}

