#!/usr/bin/env perl
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Getopt::Std;

use mtg;

getopts('N:n:h', \%opts);

if ($opts{'h'}) {
	die "-n: search by expansion, -N: seach by expansion list\n";
}

if ($opts{'l'}) {
	mtg::list_exp;
	exit;
}

%karty = mtg::read_base;
# $i = 0;
$total = 0;

if ($opts{'N'}) { 
	my @tmp = split /[ ,]/, $opts{'N'}; 
	%exps = map { $_, 1 } @tmp;
}

if ($opts{'n'}) {
	$exps{$opts{'n'}} = 1;
}

foreach $exp (keys %exps) {
	if ($mtg::expansions{ $exp }) {
		delete $exps{$exp};
		$exps{$mtg::expansions{ $exp }}=1;
	}
}

foreach $id (keys %karty) {
	$entry = mtg::get_entry($id);

	if (($entry->{rare} eq 'Basic Land') or (%exps and (! exists $exps{$entry->{exp}} ) ) ) { 
#		print "skipping $entry->{title}\n";
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
