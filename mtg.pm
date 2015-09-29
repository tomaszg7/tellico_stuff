package mtg;

use File::Fetch;
use MIME::Base64 qw(encode_base64);
use File::Copy;

sub __kolory {
 my $tekst = $_[0];
	$tekst =~ s/\sor\s/\//g;
	$tekst =~ s/Red/R/g;
	$tekst =~ s/Blue/U/g;
	$tekst =~ s/Green/G/g;
	$tekst =~ s/Black/B/g;
	$tekst =~ s/White/W/g;
	$tekst =~ s/Variable Colorless/X/g;
    return $tekst;
}

sub entry {
    my $numer = $_[0];
    my $i =  $_[1];
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

    my $xmltypes;
    my $xmlsubtypes;

    my $ff = File::Fetch->new(uri => "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=$numer");
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
	    $mana=__kolory($mana);
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
	    $ctext =~ s/<img.*?alt="(.*?)".*?\/>/__kolory($1)/eg;
	    $ctext =~ s|<.+?>||g;
	    $ctext =~ s/&/&amp;/;
	}
	elsif (/Flavor Text:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($ftext) =  ($linia =~ /\s*(.*)<\/div>/ );
	    $ftext =~ s/<\/div>/\n\n/g;
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
#####
	if ($types =~ /(.*)\s*\x{e2}\x{80}\x{94}\s*(.*)/) {
	    my $t = $1; my $st= $2;
	    if ($t =~ /(Basic.*Land)/) {
		$xmltypes="<types>$1<\/types>";
	    } else {
		$xmltypes="<types>".join("<\/types>\n<types>",split(" ", $t))."<\/types>"
	    }
	    if ($st =~ /(Urza.*(Power|Mine|Tower).*)/) {
		$xmlsubtypes = "<subtypes>".$1."<\/subtypes>";
	    } else {
		$xmlsubtypes = "<subtypes>".join("<\/subtypes>\n<subtypes>",split(" ", $st))."<\/subtypes>";
	    }
	}
	else {
	    if ($types =~ /(World Enchantment|Enchant Creature)/) {
		$xmltypes="<types>$1<\/types>";
	    } else {
		$xmltypes="<types>".join("<\/types>\n<types>",split(" ", $types))."<\/types>"
	    }
	}
#####

return <<ENTRY;
<entry id="$i">
<multiverseid>$numer</multiverseid>
<title>$name</title>
<mana-cost>$mana</mana-cost>
<typess>
$xmltypes
</typess>
<subtypess>
$xmlsubtypes
</subtypess>
<power>$p</power>
<tough>$t</tough>
<card-number>$cnum</card-number>
<expansion>$exp</expansion>
<rarity>$rare</rarity>
<illustrators>
<illustrator>$art</illustrator>
</illustrators>
<flavor-text>$ftext</flavor-text>
<card-text>$ctext</card-text>
<color>$color</color>
<picture>$numer.jpeg</picture>
</entry>
ENTRY
} #sub entry

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
   <field title="Illustrator" flags="0" category="General" format="4" description="New Field 2" type="1" name="illustrator"/>
   <field title="Variant" flags="0" category="General" format="4" description="New Field 8" type="1" name="variant"/>
   <field title="Flavor Text" flags="0" category="Flavor Text" format="4" description="New Field 1" type="2" name="flavor-text"/>
   <field title="Picture" flags="0" category="Picture" format="4" description="New Field 1" type="10" name="picture"/>
</fields>
HEAD
}

sub image {
    my $numer = $_[0];

    my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid='.$numer.'&type=card');
    my $where = $ff->fetch( to => '/tmp' ) or die $ff->error;;

    open my $pic, $where;
    
    my $out = '<image format="JPEG" id="'.$numer.'.jpeg">';
    while (read($pic, $buf, 60*57)) {
	$out .= encode_base64($buf);
    }
    close $pic;
    $out .= '</image>';
    return $out;
}

sub image_ext {
    my $numer = $_[0];

    unless ( -f "out_files/".$numer.".jpeg" ) {
      my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid='.$numer.'&type=card');
      my $where = $ff->fetch( to => '/tmp' ) or die $ff->error;
      move $where, "out_files/".$numer.".jpeg";
    }
    return '<image format="JPEG" id="'.$numer.'.jpeg"/>';
}


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
    return @lista;
}

sub __search_wyniki {
  $wyniki = $_[0];
  %lst = $_[1];

  while (<$wyniki>) {
    if (/<span class=\"cardTitle\">/) {
	$linia=<$wyniki>;
 	if ($linia =~ /href=\"\.\.\/Card\/Details\.aspx\?multiverseid=(\d+)\">(.*)<\/a>/) {
#	if ($linia =~ /multiverseid=(\d+)\">(.*)<\/a/) {
	      $id = $1; $nm = $2; undef $r;
 	      while (($lin = <$wyniki>) && !$r) {
		if ($lin =~ /;rarity=(.)\"/) {
		    $r=$1;
		}
 	      }

 	      $lst{ $id } = $nm." ".$r;
	}
    }
  }
  return %lst;
} # sub search_wyniki

sub build_checklist {
  $sstr = $_[0];
  $sstr =~ s/\s+/+/g;
  $sstr = "set=[\"".$sstr."\"]"; #output=checklist&

  my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Pages/Search/Default.aspx?'.$sstr);
  my $where = $ff->fetch(to => '/tmp') or die $ff->error;;

  open $wyniki, $where;

  my @strony; my $str_no;
  my %lista;

  while (<$wyniki>) {
    $str_no = push @strony ,  /Default\.aspx\?page=(\d+)&/g;
  }

  seek ($wyniki, 0, 0);
  %lista = __search_wyniki $wyniki, %lista;
  close $wyniki;

  #calculate number of pages
  $str_no=($str_no-4)/2;

  foreach $i (1..$str_no)
  {
    my $ff = File::Fetch->new(uri => $surl.$sstr."&page=$i");
    my $where = $ff->fetch(to => '/tmp') or die $ff->error;;

    open $wyniki, $where;
    %lista = __search_wyniki $wyniki, %lista;
    close $wyniki;

  }
  return %lista;
} #sub build_checklist

1;