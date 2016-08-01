#!/usr/bin/env perl
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use mtg;

%karty = mtg::read_base;

foreach $i (keys %mtg_pseudo::pseudo) {
   if (exists $karty{ $i }) {
       print "$i $lista{ $i }\n";
   }
}

