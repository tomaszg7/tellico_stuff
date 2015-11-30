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
} # sub save_base


getopts('c:n:', \%opts);

if (!$opts{'n'}) { die "-n - search by expansion, -c - limit to color WUBRG.\n";}

my $exp = $opts{'n'};
if (%mtg::expansions{ $exp }) {$exp = %mtg::expansions{ $exp }};

%lista = mtg::build_checklist $exp;

# @list = (keys %lista)[0..2]; #wybranie 3 pierwszych elementow
@list = keys %lista;
@list2=@list;

$out = mtg::header;

$i=0;
while ($n = shift @list)
{
  $out .= mtg::entry $n, $i;
  $i++;
}

$out .= '<images>';

unless (-d "out_files" ) { mkdir "out_files"; }

while ($n = shift @list2)
{
  $out .= mtg::image_ext $n;
}


$out .= '</images></collection></tellico>';

save_base $out;