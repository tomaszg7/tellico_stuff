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

  $baza = Archive::Zip->new();
  unless ( $baza->read( '../mtg-liga3.tc' ) == AZ_OK ) {
       die 'read error';
  }
  foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
      $_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
      $lst{ $1 } = "1";
  }
  
  return %lst;
} # sub read_base

getopts('N:n:quCURMLh', \%opts);

unless (($opts{'n'}) || ($opts{'N'})) { die "-n - search by expansion, -N - seach by expansion list, -q - print only summary, -u - print id.\n";}

%karty = read_base;

my @exps = split /[ ,]/, $opts{'N'};
if ($opts{'n'}) { push @exps, $opts{'n'} }

foreach $exp (@exps) {
if ($mtg::expansions{ $exp }) {$exp = $mtg::expansions{ $exp }};

%lista = mtg::build_checklist $exp;

if (keys( %lista) == 0) { die "Wrong expansion name.\n"; }

$j=0;

my @out;

my $do_grep = 0;

if (($opts{'C'}) | ($opts{'U'}) | ($opts{'R'}) | ($opts{'M'}) | ($opts{'L'})) { $do_grep = 1; }


foreach $i (keys %lista) {
   if ((!exists $karty{ $i }) && ((!$do_grep) || (exists $opts{substr $lista { $i }, -1}  ))) {
       push @out, ($opts{'u'}) ? "$i $lista{ $i }" : "$lista{ $i }";
       $j++;
   }
}

unless ($opts{'q'}) { print "\n$exp:\n\n"; print "$_\n" for sort(@out); };

print "$exp: $j cards missing";
if ($do_grep){
  print " with rarity mask "; 
  foreach $r ("C", "U", "R", "M", "L") {
     if (exists $opts{ $r }) {
       print $r;
    }
 }
}
else {
  print ", ".keys( %lista)." cards total, ".int((1-$j/keys(%lista))*100)."\% complete";
}
print ".\n";
}