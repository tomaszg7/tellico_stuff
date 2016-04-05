#!/usr/bin/env perl
#use Getopt::Std;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use mtg;

%lst; %lst_liga;

my $baza = Archive::Zip->new();
unless ( $baza->read( '../../mtg.tc' ) == AZ_OK ) {
  die 'read error';
}
foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
  $_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
  $lst{ $1 } = "1";
}

my $baza = Archive::Zip->new();
unless ( $baza->read( '../mtg-liga3.tc' ) == AZ_OK ) {
  die 'read error';
}
foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
  $_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
  $lst_liga{ $1 } = "1";
}

@brak;

$j=0;

foreach $i (keys %lst_liga) {
  unless (exists $lst{ $i } || exists $brak{ $i }) {
    $entry = mtg::get_entry $i, 0;
    $brak{ $i } = $i." ".$entry->{title}." ".substr $entry->{rare}, 0, 1;
    $j++;
  }
}

print "$_\n" for sort(values %brak);

# print "$exp: $j cards missing, ".keys( %lista)." cards total, ".int((1-$j/keys(%lista))*100)."\% complete.\n";