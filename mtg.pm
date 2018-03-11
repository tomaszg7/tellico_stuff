package mtg;

use File::Fetch;
use MIME::Base64 qw(encode_base64);
use File::Copy;
use Storable;

use mtg_pseudo;
use mtg_ext;

$cache_dir = $ENV{"HOME"}."/.cache/mtg_perl";
$cache_ver = undef;
$cache_price_TTL = 14; #in days

sub __kolory {
my $tekst = $_[0];
	$tekst =~ s/\sor\s/\//g;
	$tekst =~ s/Phyrexian Red/R\/P/g;
	$tekst =~ s/Phyrexian Blue/U\/P/g;
	$tekst =~ s/Phyrexian Green/G\/P/g;
	$tekst =~ s/Phyrexian Black/B\/P/g;
	$tekst =~ s/Phyrexian White/W\/P/g;

	$tekst =~ s/Red/R/g;
	$tekst =~ s/Blue/U/g;
	$tekst =~ s/Green/G/g;
	$tekst =~ s/Black/B/g;
	$tekst =~ s/White/W/g;
	$tekst =~ s/Variable Colorless/X/g;
	$tekst =~ s/Colorless/C/g;
	$tekst =~ s/Energy/E/g;
	$tekst =~ s/Snow/S/g;
	return $tekst;
} #sub kolory

sub get_entry {
	my $numer = $_[0];
	my %entry;

	if ( -f "$cache_dir/cards/$numer" ) {
		my $entry_cached = retrieve("$cache_dir/cards/$numer");
		if ( $entry_cached->{cache_ver} == $cache_ver ) {
			return $entry_cached;
		}
	}

	my $ff = File::Fetch->new(uri => "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=$numer");
	my $where = $ff->fetch(to => '/tmp') or die $ff->error;;
	my $i = 0;
	my $ii = 0;

	$entry{number} = $numer;

	open my $datafile, $where;
	while (<$datafile>) {
		if (/Card Name:<\/div>/) {
			$i++;
			$linia=<$datafile>;
			$linia=<$datafile>;
			($entry{name.$i}) =  ($linia =~ /\s*(.*)<\/div>/ );
			$entry{name.$i} =~ s/&/&amp;/;
		}
		elsif (/Mana Cost:<\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			@spl = split(/\/>/,$linia);
			while ($ss = shift @spl) {
				if ($ss =~ /alt=\"(.+?)\"/) {
					$entry{mana.$i} .= $1;
				}
			}
			$entry{mana.$i}=__kolory($entry{mana.$i});
		}
		elsif (/Types:<\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			($entry{types.$i}) =  ($linia =~ /\s*(.*)<\/div>/ );
		}
		elsif (/Card Text:<\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			($entry{ctext.$i}) =  ($linia =~ /\s*(.*)<\/div>/ );
			$entry{ctext.$i} =~ s/<\/div>/\n\n/g;
			$entry{ctext.$i} =~ s/<img.*?alt="(.*?)".*?\/>/__kolory($1)/eg;
			$entry{ctext.$i} =~ s|<.+?>||g;
			$entry{ctext.$i} =~ s/&/&amp;/;
		}
		elsif (/Flavor Text:<\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			($entry{ftext.$i}) =  ($linia =~ /\s*(.*)<\/div>/ );
			$entry{ftext.$i} =~ s/<\/div>/\n\n/g;
			$entry{ftext.$i} =~ s|<.+?>||g;
			$entry{ftext.$i} =~ s/&/&amp;/;
		}
		elsif (/<b>P\/T:<\/b><\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			if ($linia =~ /\s*(.*)\s\/\s(.*)<\/div>/ ) {
				$entry{p.$i}=$1;
				$entry{t.$i}=$2;
			}
		}
		elsif (/Expansion:<\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			$linia=<$datafile>;
			$linia=<$datafile>;
			($entry{exp}) =  ($linia =~ /.*\">(.*)<\/a>/ );
			$entry{exp} =~ s/Magic.*Conspiracy/Conspiracy/;
		}
		elsif (/Rarity:<\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			($entry{rare}) =  ($linia =~ /\'>(.*)<\/span><\/div>/ );
		}
		elsif (/Card Number:<\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			($entry{cnum}) =  ($linia =~ /\s*(.*)<\/div>/ );
		}
		elsif (/Artist:<\/div>/) {
			$linia=<$datafile>;
			$linia=<$datafile>;
			($entry{art.$i}) =  ($linia =~ /\">(.*)<\/a><\/div>/ );
			$entry{art.$i} =~ s/&/&amp;/;
		}
		elsif (/Image\.ashx\?multiverseid=(\d+)&amp;type=card/) {
			$ii++;
			if (($ii==1) || ($entry{image1} != $1)) {
				$entry{image.$ii} = $1;
			}
		}
	}

	close $datafile;
	$entry{faces} = $i;
	if ($i>2) {print STDERR "Warning: found more faces than 2.\n";}

	my $j=0;
	foreach $i (1..$entry{faces}) {
		if ($entry{mana.$i} =~ /R/ ) {
			$entry{color}="Red";
			$j++;
		}
		if ($entry{mana.$i} =~ /B/ ) {
			$entry{color}="Black";
			$j++;
		}
		if ($entry{mana.$i} =~ /U/ ) {
			$entry{color}="Blue";
			$j++;
		}
		if ($entry{mana.$i} =~ /G/ ) {
			$entry{color}="Green";
			$j++;
		}
		if ($entry{mana.$i} =~ /W/ ) {
			$entry{color}="White";
			$j++;
		}
		if ($j > 1 ) {
			$entry{color}="Multi";
		}
		elsif ($entry{types} =~ /[lL]and/ ) {
			$entry{color}="Land";
		}
		elsif ($j == 0) {
			$entry{color}="Colorless";
		}

		if ($entry{types.$i} =~ /(.*)\s*\x{e2}\x{80}\x{94}\s*(.*)/) {
			my $t = $1; my $st= $2;
			if ($t =~ /Basic ?(.*?) Land/) { #takes care of snow lands
				$entry{xmltypes.$i}="<types>Basic Land<\/types><types>$1<\/types>";
			}
			else {
				$entry{xmltypes.$i}="<types>".join("<\/types>\n<types>",split(" ", $t))."<\/types>"
			}
			if ($st =~ /(Urza.*(Power|Mine|Tower).*)/) {
				$entry{xmlsubtypes.$i} = "<subtypes>".$1."<\/subtypes>";
			}
			else {
				$entry{xmlsubtypes.$i} = "<subtypes>".join("<\/subtypes>\n<subtypes>",split(" ", $st))."<\/subtypes>";
			}
		}
		else {
			if ($entry{types.$i} =~ /(Basic Land|World Enchantment|Enchant Creature)/) {
				$entry{xmltypes.$i}="<types>$1<\/types>";
			} 
			else {
				$entry{xmltypes.$i}="<types>".join("<\/types>\n<types>",split(" ", $entry{types.$i}))."<\/types>"
			}
		}
	}

	if ($entry{faces}>=2) {
		$entry{title} = $entry{name1}." // ".$entry{name2};
		if ($entry{ftext2}) {$entry{ftext} = $entry{ftext1}."\n\n-----------------------\n\n".$entry{ftext2};}
		if ($entry{ctext2}) {$entry{ctext} = $entry{ctext1}."\n\n-----------------------\n\n".$entry{ctext2};}
	}
	else {
		$entry{title} = $entry{name1};
		$entry{ftext} = $entry{ftext1};
		$entry{ctext} = $entry{ctext1};
	}

	unless (-d "$cache_dir/cards" ) { mkdir "$cache_dir/cards"; }
	$entry{cache_ver} = $cache_ver;
	store \%entry, "$cache_dir/cards/$numer";

	return \%entry;
} #sub get_entry  

sub print_entry {
	my $entry = $_[0];
	my $n =  $_[1];

	$res = <<ENTRY;
<entry id="$n">
<multiverseid>$entry->{number}</multiverseid>
<title>$entry->{title}</title>
<mana-cost>$entry->{mana1}</mana-cost>
<typess>
$entry->{xmltypes1}
$entry->{xmltypes2}
</typess>
<subtypess>
$entry->{xmlsubtypes1}
$entry->{xmlsubtypes2}
</subtypess>
<power>$entry->{p1}</power>
<tough>$entry->{t1}</tough>
<card-number>$entry->{cnum}</card-number>
<expansion>$entry->{exp}</expansion>
<rarity>$entry->{rare}</rarity>
<illustrators>
<illustrator>$entry->{art1}</illustrator>
<illustrator>$entry->{art2}</illustrator>
</illustrators>
<flavor-text>$entry->{ftext}</flavor-text>
<card-text>$entry->{ctext}</card-text>
<color>$entry->{color}</color>
<picture>$entry->{image1}.jpeg</picture>
ENTRY

	if ($entry->{faces}>=2) {
		$res .= <<ALT_ENTRY;
<altmana-cost>$entry->{mana2}</altmana-cost>
<altpower>$entry->{p2}</altpower>
<alttough>$entry->{t2}</alttough>
<variant>Multi</variant>
ALT_ENTRY
	}

	if ($entry->{image2}) {
		$res .= "<altpicture>$entry->{image2}.jpeg</altpicture>"
	}
	$res .="</entry>";

	return $res;
} #sub print_entry

sub header {
	return <<HEAD;
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE tellico PUBLIC "-//Robby Stephenson/DTD Tellico V11.0//EN" "http://periapsis.org/tellico/dtd/v11/tellico.dtd"><tellico xmlns="http://periapsis.org/tellico/" syntaxVersion="11">
<collection title="My Collection" type="1">
<fields>
<field title="multiverseid" flags="0" category="General" format="4" description="New Field 1" type="6" name="multiverseid"/>
<field title="Name" flags="0" category="General" format="1" description="Title" type="1" name="title"/>
<field title="Color" flags="2" category="General" format="4" description="New Field 4" type="3" allowed="Black;Blue;Red;Green;White;Multi;Colorless;Land" name="color"/>
<field title="Mana Cost" flags="0" category="General" format="4" description="New Field 1" type="1" name="mana-cost"/>
<field title="Types" flags="7" category="General" format="4" description="New Field 1" type="1" name="types"/>
<field title="Subtypes" flags="7" category="General" format="4" description="New Field 1" type="1" name="subtypes"/>
<field title="Card Text" flags="0" category="Card Text" format="4" description="New Field 2" type="2" name="card-text"/>
<field title="Power" flags="0" category="General" format="4" description="New Field 3" type="1" name="power"/>
<field title="Tough" flags="0" category="General" format="4" description="New Field 4" type="1" name="tough"/>
<field title="Expansion" flags="0" category="General" format="4" description="New Field 5" type="1" name="expansion"/>
<field title="Rarity" flags="0" category="General" format="4" description="New Field 6" type="1" name="rarity"/>
<field title="Card Number" flags="0" category="General" format="4" description="New Field 8" type="1" name="card-number"/>
<field title="Illustrator" flags="7" category="General" format="4" description="New Field 2" type="1" name="illustrator"/>
<field title="Variant" flags="7" category="General" format="4" description="New Field 8" type="1" name="variant"/>
<field title="Flavor Text" flags="0" category="Flavor Text" format="4" description="New Field 1" type="2" name="flavor-text"/>
<field title="Picture" flags="0" category="Picture" format="4" description="New Field 1" type="10" name="picture"/>
<field title="AltMana Cost" flags="0" category="Second face" format="4" description="New Field 1" type="1" name="altmana-cost"/>
<field title="AltPower" flags="2" category="Second face" format="4" description="New Field 4" type="1" name="altpower"/>
<field title="AltTough" flags="2" category="Second face" format="4" description="New Field 5" type="1" name="alttough"/>
<field title="AltIllustrator" flags="7" category="Second face" format="4" description="New Field 6" type="1" name="altillustrator"/>
<field title="AltPicture" flags="0" category="AltPicture" format="4" description="New Field 9" type="10" name="altpicture"/>
</fields>
HEAD
} #sub header

sub image {
	my $numer = $_[0];

	unless ( -f "$cache_dir/images/$numer.jpeg" ) {
		my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid='.$numer.'&type=card');
		my $where = $ff->fetch( to => '/tmp' ) or die $ff->error;;
		move $where, "$cache_dir/images/$numer.jpeg";
	}

	open my $pic, "$cache_dir/images/$numer.jpeg";
	my $out = '<image format="JPEG" id="'.$numer.'.jpeg">';
	while (read($pic, $buf, 60*57)) {
		$out .= encode_base64($buf);
	}
	close $pic;

	$out .= '</image>';

	return $out;
} #sub image

sub image_ext {
	my $numer = $_[0];

	unless ( -f "out_files/".$numer.".jpeg" ) {
		unless ( -f "$cache_dir/images/$numer.jpeg" ) {
			my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid='.$numer.'&type=card');
			my $where = $ff->fetch( to => '/tmp' ) or die $ff->error;;
			move $where, "$cache_dir/images/$numer.jpeg";
		}
		move "$cache_dir/images/$numer.jpeg", "out_files/";
	}
	return '<image format="JPEG" id="'.$numer.'.jpeg"/>';
} #sub image_ext


sub search {
	$sstr = $_[0];
	my @lista;

	my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Pages/Search/Default.aspx?'.$sstr);
	my $where = $ff->fetch(to => '/tmp') or die $ff->error;;

	open my $wyniki, $where;

	while (<$wyniki>) {
		push @lista ,  /multiverseid=(\d+)[\'\"]/g;
	}
	close $wyniki;

	#zmiana na hash, pozbycie sie duplikatow
	my %hash = map { $_, 1 } @lista;

	#remove pseudo-cards from the lists
	for my $key ( keys %pseudo ) {
		delete $hash{$key};
	}

	return %hash;
} #sub search

sub __parse_wyniki {
	$wyniki = $_[0];

	while (<$wyniki>) {
#     if (/<span class=\"cardTitle\">/) {
# 	$linia=<$wyniki>;
#  	if ($linia =~ /href=\"\.\.\/Card\/Details\.aspx\?multiverseid=(\d+)\">(.*)<\/a>/) {
# #	if ($linia =~ /multiverseid=(\d+)\">(.*)<\/a/) {
#       if (/multiverseid=(\d+).*\'SameWindow\'\)\;\">(.+)<\/a>.*\"rarity\">(.*)<\/td><td/) {
# 	      $id = $1; $nm = $2; undef $r;
#  	      while (($lin = <$wyniki>) && !$r) {
# 		if ($lin =~ /;rarity=(.)\"/) {
# 		    $r=$1;
# 		}
#  	      }
#                     </td>
#                 </tr>
# 
#  	      $lista{ $1 } = $2." ".$3;

		if  (/<a id=.*cardTitle.*multiverseid=\d+\">(.*)<\/a>/) {
			$nm = $1; undef $flag; #print "$1\n";
			while (($lin = <$wyniki>) && !$flag) {
				if ($lin =~ /\?multiverseid=/) {
# 			    	print "$lin\n";
					while ($lin =~ /\?multiverseid=(\d+).+?\;rarity=(.)\"/g) {
						$lista{ $1 } = $nm." ".$2;
# 						print "$1 $nm $2\n";
					};
				$flag=1;
				}
			}
		}
	}

	return 1;
} # sub parse_wyniki

sub build_checklist {
	$set = $_[0];
	$set =~ s/\s+/+/g;
	$type = $_[1];
	$sstr = "output=compact&".$type."=[\"".$set."\"]"; #output=checklist&

	%lista = ();

	if ( -f "$cache_dir/sets/$set" ) {
		%lista = %{retrieve("$cache_dir/sets/$set")};
	}
	else {
		my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Pages/Search/Default.aspx?'.$sstr);
		my $where = $ff->fetch(to => '/tmp') or die $ff->error;;

		open $wyniki, $where;

		my @strony; my $str_no;

		while (<$wyniki>) {
			$str_no = push @strony ,  /Default\.aspx\?page=(\d+)&/g;
		}

		seek ($wyniki, 0, 0);
		__parse_wyniki $wyniki;
		close $wyniki;

		#calculate number of pages
		$str_no=($str_no-4)/2;

		foreach $i (1..$str_no) {
			my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Pages/Search/Default.aspx?'.$sstr."&page=$i");
			my $where = $ff->fetch(to => '/tmp') or die $ff->error;;

			open $wyniki, $where;
			__parse_wyniki $wyniki;
			close $wyniki;
		}
		if ($type == "set") {
			unless (-d "$cache_dir/sets" ) { mkdir "$cache_dir/sets"; }
			unless (keys( %lista) == 0) { store \%lista, "$cache_dir/sets/$set"; }
		}
	}

	#remove pseudo-cards from the lists
	for my $key ( keys %pseudo ) {
		delete $lista{$key};
	}

return %lista;
} #sub build_checklist

sub read_base {
	use mtg_bases;

	my %lst;

	for $base (@bases) {
		my $baza = Archive::Zip->new();
		unless ( $baza->read( $base ) == AZ_OK ) {
			die 'read error';
		}
		foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
			$_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
			$lst{ $1 } ++;
		}
	}

	return %lst;
} # sub read_base

sub get_price {
	my $numer = $_[0];
	my $title = $_[1];
	my $exp = $_[2];
	my $cena;

	unless ($title && $exp) {
		my $entry = get_entry $numer;
		$title = $entry->{title};
		$exp = $entry->{exp};
	}


	$exp =~ s/ Core Set//;
	$exp =~ s/Commander 2013 Edition/Commander 2013/;
	$exp =~ s/Modern Masters 2015 Edition/Modern Masters 2015/;
	$exp =~ s/Modern Masters 2017 Edition/Modern Masters 2017/;
	$exp =~ s/Revised Edition/Revised/;
	$exp =~ s/Unlimited Edition/Unlimited/;
	$exp =~ s/Limited Edition Beta/Beta/;
	$exp =~ s/Limited Edition Alpha/Alpha/;
	$exp =~ s/Classic //;
	$exp =~ s/ \"Timeshifted\"//;

# 	$title =~ s/\/\//%2F/; # replace // by %2F
# 	$title =~ s/Æ/Ae/;

	my $exp_prices = {};
	if ( -f "$cache_dir/prices/$exp" ) {
		$exp_prices = retrieve("$cache_dir/prices/$exp");
		if ( $exp_prices->{$numer} && (time() - $exp_prices->{$numer}->{"time"} < $cache_price_TTL * 24 * 60 * 60)) {
			return $exp_prices->{$numer}->{price};
		}
	}

	my $sstr = $exp."/".$title;
	$sstr =~ s/\s+/+/g;

SEARCH:
	my $ff = File::Fetch->new(uri => 'http://www.magiccardmarket.eu/Products/Singles/'.$sstr);
	my $where = $ff->fetch(to => '/tmp'); #or return;

	open my $wyniki, $where;
	while (<$wyniki>) {
		if (/Price Trend:<\/td><td class=.*?>([\d,]+) &#x20AC;/) {
			$cena = $1;
			$cena =~ s/,/\./; #convert decimal mark
			last;
		}
	}
	close $wyniki;

#some cards use Æ while other use Ae
		if (!$cena && ($title =~ /Æ/)) {
			$title =~ s/Æ/Ae/;
			goto SEARCH;
		}

#some cards use / while other use //
#     if (!$cena && ($title =~ /%2F/)) {
# 		$title =~ s/%2F/%2F%2F/;
# 		goto SEARCH;
#     }

	unless ($cena) { print STDERR "Entry not found: $sstr\n"; }

	unless (-d "$cache_dir/prices" ) { mkdir "$cache_dir/prices"; }
	if ($cena && $numer) {
		$exp_prices->{$numer} = { price => $cena, "time" => time(), "title" => $title };
		store $exp_prices, "$cache_dir/prices/$exp";
	}

	return $cena;
} #sub get_price

1;
