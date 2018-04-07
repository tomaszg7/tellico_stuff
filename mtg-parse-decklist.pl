#!/usr/bin/env perl
use Getopt::Std;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use mtg;

# $url = 'http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=';
# $iurl= 'http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=';
# $iurl2= '&type=card';
# $surl= 'http://gatherer.wizards.com/Pages/Search/Default.aspx?';

sub save_base {
	$dane = $_[0];

	my $baza = Archive::Zip->new();
	$baza->addString( $dane, 'tellico.xml' );
	unless ( $baza->writeToFileNamed('out.tc') == AZ_OK ) {
		die 'write error';
	}
} #sub save_base


getopts('d:n:', \%opts);

if (!$opts{'d'} && !$opts{'n'}) { die "-d - file with deck list, -n - expansion name\n";}

my $file = $opts{'d'};
my $exp = $opts{'n'};
if ($mtg::expansions{ $exp }) {
	$exp = $mtg::expansions{ $exp };
}

my %lista;

open $fd, $file;

while (<$fd>) {
	if (/^(\d+)\s+(.+?)\r?$/) {
		%result = mtg::search "name=+[\"". $2. "\"]&set=+[\"".$exp."\"]", 1 ;
		$uid = (keys %result)[0];
		$lista { $uid } += $1;
# 		print $2.", ".$uid."\n";
# 		print "search string: "."name=+[\"". $2. "\"]&set=+[\"".$exp."\"]\n";
	}
}

close $fd;

@list = keys %lista;

$out = mtg::header;

$i=0;
my @images;

while ($n = shift @list) {
	$entry = mtg::get_entry $n;
	$out .= mtg::print_entry ($entry, $i);
	push @images, $entry->{image1};
	if ($entry->{image2}) {
		push @images, $entry->{image2};
	}
	$i++;
}

$out .= '<images>';

unless (-d "out_files" ) { mkdir "out_files"; }

while ($n = shift @images) {
	$out .= mtg::image_ext $n;
}


$out .= '</images></collection></tellico>';

save_base $out;
