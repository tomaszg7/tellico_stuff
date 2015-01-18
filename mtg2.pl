#!/usr/bin/env perl
use MIME::Base64 qw(encode_base64);
use Getopt::Std;
use File::Fetch;


#$sstr = $ARGV[0];
$url = 'http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=';
$iurl= 'http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=';
$iurl2= '&type=card';
$surl= 'http://gatherer.wizards.com/Pages/Search/Default.aspx?';


sub kolory {
 my $tekst = $_[0];
	$tekst =~ s/\sor\s/\//g;
	$tekst =~ s/Red/R/g;
	$tekst =~ s/Blue/U/g;
	$tekst =~ s/Green/G/g;
	$tekst =~ s/Black/B/g;
	$tekst =~ s/White/W/g;
    $tekst;
}

sub header {
print <<HEAD;
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE tellico PUBLIC "-//Robby Stephenson/DTD Tellico V11.0//EN" "http://periapsis.org/tellico/dtd/v11/tellico.dtd"><tellico xmlns="http://periapsis.org/tellico/" syntaxVersion="11">
<collection title="My Collection" type="1">
<fields>
    <field title="multiverseid" flags="0" category="General" format="4" description="New Field 1" type="6" name="multiverseid"/>
    <field title="Name" flags="0" category="General" format="1" description="Title" type="1" name="title"/>
    <field title="Color" flags="2" category="General" format="4" description="New Field 4" type="3" allowed="Black;Blue;Red;Green;White;Multi;Colorless;Land" name="color"/>
    <field title="Mana Cost" flags="0" category="General" format="4" description="New Field 1" type="1" name="mana-cost"/>
   <field title="Types" flags="0" category="General" format="4" description="New Field 1" type="1" name="types"/>
   <field title="Card Text" flags="0" category="Card Text" format="4" description="New Field 2" type="2" name="card-text"/>
   <field title="Power" flags="0" category="General" format="4" description="New Field 3" type="1" name="power"/>
   <field title="Tough" flags="0" category="General" format="4" description="New Field 4" type="1" name="tough"/>
   <field title="Expansion" flags="0" category="General" format="4" description="New Field 5" type="1" name="expansion"/>
   <field title="Rarity" flags="0" category="General" format="4" description="New Field 6" type="1" name="rarity"/>
   <field title="Card Number" flags="0" category="General" format="4" description="New Field 8" type="1" name="card-number"/>
   <field title="Illustrator" flags="0" category="General" format="4" description="New Field 2" type="1" name="illustrator"/>
   <field title="Variant" flags="0" category="General" format="4" description="New Field 8" type="1" name="variant"/>
   <field title="Flavor Text" flags="0" category="Flavor Text" format="4" description="New Field 1" type="2" name="flavor-text"/>
   <field title="Picture" flags="0" category="Picture" format="4" description="New Field 1" type="10" name="picture"/>
</fields>
HEAD
}

sub entry {
    my $numer = $_[0];
    my $mana;
    my $name;
    my $types;
    my $ctext;
    my $ftext;
    my $p; my $t;
    my $exp;
    my $rare;
    my $cnum;
    my $art;

    my $ff = File::Fetch->new(uri => "$url$numer");
    my $where = $ff->fetch(to => '/tmp') or die $ff->error;;


    open my $datafile, $where;
    while (<$datafile>) {
        if (/Card Name:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($name) =  ($linia =~ /\s*(.*)<\/div>/ );
	    $name =~ s/&/&amp;/;
	}
	elsif (/Mana Cost:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    @spl = split(/\/>/,$linia);
	    while ($ss = shift @spl) {
		if ($ss =~ /alt=\"(.+?)\"/){
		    $mana .= $1;
		}
	    }
	    $mana=kolory($mana);
	}
	elsif (/Types:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($types) =  ($linia =~ /\s*(.*)<\/div>/ );
	}
	elsif (/Card Text:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($ctext) =  ($linia =~ /\s*(.*)<\/div>/ );
	    $ctext =~ s/<\/div>/\n\n/g;
	    $ctext =~ s/<img.*?alt="(.*?)".*?\/>/kolory($1)/eg;
	    $ctext =~ s|<.+?>||g;
	    $ctext =~ s/&/&amp;/;
	}
	elsif (/Flavor Text:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($ftext) =  ($linia =~ /\s*(.*)<\/div>/ );
	    $ftext =~ s/<\/div>/\n\n/;
	    $ftext =~ s|<.+?>||g;
	    $ftext =~ s/&/&amp;/;
        }
	elsif (/<b>P\/T:<\/b><\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    if ($linia =~ /\s*(.*)\s\/\s(.*)<\/div>/ ) {
		$p=$1;
		$t=$2;
	    }
        }
	elsif (/Expansion:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($exp) =  ($linia =~ /.*\">(.*)<\/a>/ );
	    $exp =~ s/Magic.*Conspiracy/Conspiracy/;
	}
	elsif (/Rarity:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($rare) =  ($linia =~ /\'>(.*)<\/span><\/div>/ );
	}
	elsif (/Card Number:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($cnum) =  ($linia =~ /\s*(.*)<\/div>/ );
	}
	elsif (/Artist:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($art) =  ($linia =~ /\">(.*)<\/a><\/div>/ );
	    $art =~ s/&/&amp;/;
	}
    }

    close $datafile;

    my $j=0;
	if ($mana =~ /R/ ) {
	    $color="Red";
	    $j++;
	}
	if ($mana =~ /B/ ) {
	    $color="Black";
	    $j++;
	}
	if ($mana =~ /U/ ) {
	    $color="Blue";
	    $j++;
	}
	if ($mana =~ /G/ ) {
	    $color="Green";
	    $j++;
	}
	if ($mana =~ /W/ ) {
	    $color="White";
	    $j++;
	}
	if ($j > 1 ) {
	    $color="Multi";
	}
	elsif ($types =~ /[lL]and/ ) {
	    $color="Land";
	}
	elsif ($j == 0) {
	    $color="Colorless";
	}

print <<ENTRY;
<entry id="$i">
<multiverseid>$numer</multiverseid>
<title>$name</title>
<mana-cost>$mana</mana-cost>
<types>$types</types>
<power>$p</power>
<tough>$t</tough>
<card-number>$cnum</card-number>
<expansion>$exp</expansion>
<rarity>$rare</rarity>
<illustrator>$art</illustrator>
<flavor-text>$ftext</flavor-text>
<card-text>$ctext</card-text>
<color>$color</color>
<picture>$numer.jpeg</picture>
</entry>
ENTRY
$i++;
} #sub entry

sub image {
    my $numer = $_[0];

    my $ff = File::Fetch->new(uri => $iurl.$numer.$iurl2);
    my $where = $ff->fetch( to => '/tmp' ) or die $ff->error;;

    #system ("wget \'".$iurl.$numer.$iurl2."\' -O tmp$numer.jpg");

    open my $pic, $where;
#    open $pic,"tmp$numer.jpg" or die "$!";
    print '<image format="JPEG" id="'.$numer.'.jpeg">';
    while (read($pic, $buf, 60*57)) {
	print encode_base64($buf);
    }
    close $pic;
    print '</image>';
}

sub search {
    my $ff = File::Fetch->new(uri => $surl.$sstr);
    my $where = $ff->fetch(to => '/tmp') or die $ff->error;;
    #system ("wget \'".$surl."$sstr\' -O tmp.sr");

    open my $wyniki, $where;

    while (<$wyniki>) {
	push @lista ,  /multiverseid=(\d+)[\'\"]/g;
    }
    close $wyniki;
}

getopt('naN', \%opts);

if (!%opts) { die "-n - search by name, -N - search by multiverseid, -a - search by artist.\n";}

header;


if ($opts{'N'}) {
    if ($opts{'N'} =~ /\d+/ ) {
    entry $opts{'N'};
    print '<images>';
    image $opts{'N'};
    }
    else { die "-N value is not a number\n."}
}
elsif ($opts{'n'} || $opts{'a'} ) {
    if ($opts{'n'}) {
	$sstr = $opts{'n'};
	$sstr =~ s/\s+/]+[/g;
	$sstr = "name=+[".$sstr."]";
    }
    else {
	$sstr = $opts{'a'};
	$sstr =~ s/\s+/]+[/g;
	$sstr = "artist=+[".$sstr."]";
    }

    @lista;
    search;

    my %hash   = map { $_, 1 } @lista;
    my @lista = keys %hash;

    @l_tmp1=@lista[0..9];
    @l_tmp2=@l_tmp1;

    $i=0;
    while ($n = shift @l_tmp1)
    {
	entry $n;
    }
    print '<images>';
    while ($n = shift @l_tmp2)
    {
    image $n;
    }
}
print '</images></collection></tellico>';

