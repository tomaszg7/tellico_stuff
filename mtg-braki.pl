#!/usr/bin/env perl
use Getopt::Std;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use mtg;

getopts('N:n:quCURMLhslp', \%opts);

unless (($opts{'l'}) || ($opts{'n'}) || ($opts{'N'})) { die "-n: search by expansion, -N: seach by expansion list, -q: print only summary, -u: print id, -s: skip summary, -p: include prices, -l: print out aliases.\n";}

if ($opts{'l'}) {
    foreach $i (keys %mtg::expansions) {
	print $i.": ".$mtg::expansions{ $i }."\n";
    }
    die;
}

%karty = mtg::read_base;

if ($opts{'N'}) { @exps = split /[ ,]/, $opts{'N'}; }
if ($opts{'n'}) { push @exps, $opts{'n'} }

foreach $exp (@exps) {
if ($mtg::expansions{ $exp }) {$exp = $mtg::expansions{ $exp }};

%lista = mtg::build_checklist $exp, "set";

if (keys( %lista) == 0) { die "Wrong expansion name.\n"; }

$j=0;

my @out;

my $do_grep = 0;

if (($opts{'C'}) || ($opts{'U'}) || ($opts{'R'}) || ($opts{'M'}) || ($opts{'L'})) { $do_grep = 1; }


foreach $i (keys %lista) {
   if ((!exists $karty{ $i }) && ((!$do_grep) || (exists $opts{substr $lista { $i }, -1}  ))) {
       push @out, (($opts{'u'}) ? "$i ": "").$lista{ $i }.(($opts{'p'}) ? " ".mtg::get_price($lista{ $i }=~/(.*) [CURML]/,$exp): "");
       $j++;
   }
}

unless ($opts{'q'}) { print "\n$exp:\n\n"; print "$_\n" for sort(@out); };

unless ($opts{'s'}) {
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
}
