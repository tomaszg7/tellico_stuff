#!/usr/bin/env perl
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Getopt::Std;

use mtg;

getopts('N:n:u:hCURM', \%opts);

if ($opts{'h'}) {
	die "-n: search by expansion, -N: seach by expansion list, -u search by id, -l list expansion abbreviations, -C, -U, -R, -M limit the rarity";
}

if ($opts{'l'}) {
	mtg::list_exp;
	exit;
}

%karty = mtg::read_base;
# $i = 0;
$total = 0;

if ($opts{'u'}) {
	print mtg::get_price($opts{'u'})."\n";
	exit;
}

if ($opts{'N'}) { 
	my @tmp = split /[ ,]/, $opts{'N'}; 
	%exps = map { $_, 1 } @tmp;
}

if ($opts{'n'}) {
	$exps{$opts{'n'}} = 1;
}

if (($opts{'C'}) || ($opts{'U'}) || ($opts{'R'}) || ($opts{'M'}) ) {
	$rarity_check = 1;
}

foreach $exp (keys %exps) {
	if ($mtg::expansions{ $exp }) {
		delete $exps{$exp};
		$exps{$mtg::expansions{ $exp }}=1;
	}
}

foreach $id (keys %karty) {
	$entry = mtg::get_entry($id);

#grab first letter of rarity
	if ($entry->{rare} =~ /^([CURMB])/) {
		$rarity = $1;
	}

	if (($rarity eq "B") or (%exps and (! exists $exps{$entry->{exp}} ) ) or ($rarity_check and (! exists $opts{$rarity}) )) { 
# 		print "skipping $entry->{title}\n";
		next;
	}

	$pricelist->{$id}->{price} = mtg::get_price($id,$entry->{title},$entry->{exp});
	$pricelist->{$id}->{title} = $entry->{title};
	$pricelist->{$id}->{title} =~ s/%2F/\//g; 
	$pricelist->{$id}->{exp} = $entry->{exp};
	$total += $pricelist->{$id}->{price} * $karty{$id};
# 	$i++;
# 	print $i." $entry->{title} ".$pricelist->{$id}->{price}."\n";
# 	last if $i>=100;
}

foreach $id (sort { $pricelist->{$b}->{price} <=> $pricelist->{$a}->{price} } keys %$pricelist) {
    print $id.": ".$pricelist->{$id}->{title}." (".$pricelist->{$id}->{exp}."): ".$pricelist->{$id}->{price}."\n";
}

print "Total: ".sprintf("%.2f",$total)."\n";
