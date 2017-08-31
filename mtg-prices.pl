#!/usr/bin/env perl
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use mtg;

use Data::Dumper;

%karty = mtg::read_base;
$i = 0;
$total = 0;

foreach $id (keys %karty) {
	$entry = mtg::get_entry($id);

	if ($entry->{rare} eq 'Basic Land') { 
		next;
	}

	$pricelist->{$id}->{price} = mtg::get_price($id,$entry->{title},$entry->{exp});
	$pricelist->{$id}->{title} = $entry->{title};
	$pricelist->{$id}->{title} =~ s/%2F/\//g; 
	$pricelist->{$id}->{exp} = $entry->{exp};
	$total += $pricelist->{$id}->{price} * $karty{$id};
	$i++;
# 	print $i." $entry->{title} ".$pricelist->{$id}->{price}."\n";
# 	last if $i>=100;
}

# print Dumper($pricelist);

foreach $id (sort { $pricelist->{$b}->{price} <=> $pricelist->{$a}->{price} } keys %$pricelist) {
    print $id.": ".$pricelist->{$id}->{title}." (".$pricelist->{$id}->{exp}."): ".$pricelist->{$id}->{price}."\n";
}

print "Total: $total\n";
