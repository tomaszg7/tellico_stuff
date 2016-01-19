package mtg;

use File::Fetch;
use MIME::Base64 qw(encode_base64);
use File::Copy;
use Storable;


$cache_dir = $ENV{"HOME"}."/.cache/mtg_perl";

sub __kolory {
 my $tekst = $_[0];
	$tekst =~ s/\sor\s/\//g;
	$tekst =~ s/Red/R/g;
	$tekst =~ s/Blue/U/g;
	$tekst =~ s/Green/G/g;
	$tekst =~ s/Black/B/g;
	$tekst =~ s/White/W/g;
	$tekst =~ s/Variable Colorless/X/g;
	$tekst =~ s/Colorless/C/g;	
    return $tekst;
}

sub entry {
    my $numer = $_[0];
    my $i =  $_[1];
    my %entry;
    my $xmltypes;
    my $xmlsubtypes;

    if ( -f "$cache_dir/cards/$numer" ) {
      %entry = %{retrieve("$cache_dir/cards/$numer")};
    }
    else {
      my $ff = File::Fetch->new(uri => "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=$numer");
      my $where = $ff->fetch(to => '/tmp') or die $ff->error;;


    open my $datafile, $where;
    while (<$datafile>) {
        if (/Card Name:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($entry{name}) =  ($linia =~ /\s*(.*)<\/div>/ );
	    $entry{name} =~ s/&/&amp;/;
	}
	elsif (/Mana Cost:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    @spl = split(/\/>/,$linia);
	    while ($ss = shift @spl) {
		if ($ss =~ /alt=\"(.+?)\"/){
		    $entry{mana} .= $1;
		}
	    }
	    $entry{mana}=__kolory($entry{mana});
	}
	elsif (/Types:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($entry{types}) =  ($linia =~ /\s*(.*)<\/div>/ );
	}
	elsif (/Card Text:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($entry{ctext}) =  ($linia =~ /\s*(.*)<\/div>/ );
	    $entry{ctext} =~ s/<\/div>/\n\n/g;
	    $entry{ctext} =~ s/<img.*?alt="(.*?)".*?\/>/__kolory($1)/eg;
	    $entry{ctext} =~ s|<.+?>||g;
	    $entry{ctext} =~ s/&/&amp;/;
	}
	elsif (/Flavor Text:<\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    ($entry{ftext}) =  ($linia =~ /\s*(.*)<\/div>/ );
	    $entry{ftext} =~ s/<\/div>/\n\n/g;
	    $entry{ftext} =~ s|<.+?>||g;
	    $entry{ftext} =~ s/&/&amp;/;
        }
	elsif (/<b>P\/T:<\/b><\/div>/) {
	    $linia=<$datafile>;
	    $linia=<$datafile>;
	    if ($linia =~ /\s*(.*)\s\/\s(.*)<\/div>/ ) {
		$entry{p}=$1;
		$entry{t}=$2;
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
	    ($entry{art}) =  ($linia =~ /\">(.*)<\/a><\/div>/ );
	    $entry{art} =~ s/&/&amp;/;
	}
    }

    close $datafile;

    my $j=0;
	if ($entry{mana} =~ /R/ ) {
	    $entry{color}="Red";
	    $j++;
	}
	if ($entry{mana} =~ /B/ ) {
	    $entry{color}="Black";
	    $j++;
	}
	if ($entry{mana} =~ /U/ ) {
	    $entry{color}="Blue";
	    $j++;
	}
	if ($entry{mana} =~ /G/ ) {
	    $entry{color}="Green";
	    $j++;
	}
	if ($entry{mana} =~ /W/ ) {
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
    unless (-d "$cache_dir/cards" ) { mkdir "$cache_dir/cards"; }
    store \%entry, "$cache_dir/cards/$numer";
    }
	if ($entry{types} =~ /(.*)\s*\x{e2}\x{80}\x{94}\s*(.*)/) {
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
	    if ($entry{types} =~ /(World Enchantment|Enchant Creature)/) {
		$xmltypes="<types>$1<\/types>";
	    } else {
		$xmltypes="<types>".join("<\/types>\n<types>",split(" ", $entry{types}))."<\/types>"
	    }
	}


return <<ENTRY;
<entry id="$i">
<multiverseid>$numer</multiverseid>
<title>$entry{name}</title>
<mana-cost>$entry{mana}</mana-cost>
<typess>
$xmltypes
</typess>
<subtypess>
$xmlsubtypes
</subtypess>
<power>$entry{p}</power>
<tough>$entry{t}</tough>
<card-number>$entry{cnum}</card-number>
<expansion>$entry{exp}</expansion>
<rarity>$entry{rare}</rarity>
<illustrators>
<illustrator>$entry{art}</illustrator>
</illustrators>
<flavor-text>$entry{ftext}</flavor-text>
<card-text>$entry{ctext}</card-text>
<color>$entry{color}</color>
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
}

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
# 			    print "$lin\n";
		    while ($lin =~ /\?multiverseid=(\d+).+?\;rarity=(.)\"/g) {
			$lista{ $1 } = $nm." ".$2;
# 			print "$1 $nm $2\n";
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

    foreach $i (1..$str_no)
    {
      my $ff = File::Fetch->new(uri => 'http://gatherer.wizards.com/Pages/Search/Default.aspx?'.$sstr."&page=$i");
      my $where = $ff->fetch(to => '/tmp') or die $ff->error;;

      open $wyniki, $where;
      __parse_wyniki $wyniki;
      close $wyniki;

    }
    if ($type = "set") {
      unless (-d "$cache_dir/sets" ) { mkdir "$cache_dir/sets"; }
      unless (keys( %lista) == 0) { store \%lista, "$cache_dir/sets/$set"; }
    }
  }
  return %lista;
} #sub build_checklist


%expansions = (
  ATQ => 'Antiquities',
  LEG => 'Legends',
  DRK => 'The Dark',
  FEM => 'Fallen Empires',
  HML => 'Homelands',
  ICE => 'Ice Age',
  ALL => 'Alliances',
  CSP => 'Coldsnap',
  MIR => 'Mirage',
  VIS => 'Visions',
  WTH => 'Weatherlight',
  TMP => 'Tempest',
  STH => 'Stronghold',
  EXO => 'Exodus',
  USG => 'Urza\'s Saga',
  ULG => 'Urza\'s Legacy',
  UDS => 'Urza\'s Destiny',
  MMQ => 'Mercadian Masques',
  NMS => 'Nemesis',
  PCY => 'Prophecy',
  INV => 'Invasion',
  PLS => 'Planeshift',
  APC => 'Apocalypse',
  ODY => 'Odyssey',
  TOR => 'Torment',
  JUD => 'Judgment',
  ONS => 'Onslaught',
  LGN => 'Legions',
  SCG => 'Scourge',
  MRD => 'Mirrodin',
  DST => 'Darksteel',
  "5DN" => 'Fifth Dawn',
  CHK => 'Champions of Kamigawa',
  BOK => 'Betrayers of Kamigawa',
  SOK => 'Saviors of Kamigawa',
  RAV => 'Ravnica: City of Guilds',
  GPT => 'Guildpact',
  DIS => 'Dissension',
  TSP => 'Time Spiral',
  PLC => 'Planar Chaos',
  FUT => 'Future Sight',
  LRW => 'Lorwyn',
  MOR => 'Morningtide',
  SHM => 'Shadowmoor',
  EVE => 'Eventide',
  ALA => 'Shards of Alara',
  CON => 'Conflux',
  ARB => 'Alara Reborn',
  ZEN => 'Zendikar',
  WWK => 'Worldwake',
  ROE => 'Rise of the Eldrazi',
  SOM => 'Scars of Mirrodin',
  MBS => 'Mirrodin Besieged',
  NPH => 'New Phyrexia',
  ISD => 'Innistrad',
  DKA => 'Dark Ascension',
  AVR => 'Avacyn Restored',
  RTR => 'Return to Ravnica',
  GTC => 'Gatecrash',
  DGM => 'Dragon\'s Maze',
  THS => 'Theros',
  BNG => 'Born of the Gods',
  JOU => 'Journey into Nyx',
  KTK => 'Khans of Tarkir',
  FRF => 'Fate Reforged',
  DTK => 'Dragons of Tarkir',
  BFZ => 'Battle for Zendikar',
  EXP => 'Zendikar Expedition',
  OGW => 'Oath of the Gatewatch',
  CHR => 'Chronicles',
  MMA => 'Modern Masters',
  MM2 => 'Modern Masters 2015 Edition',
  CMD => 'Magic: The Gathering-Commander',
  C13 => 'Commander 2013 Edition',
  C14 => 'Commander 2014',
  C15 => 'Commander 2015',
  CNS => 'Magic: The Gathering—Conspiracy',
  POR => 'Portal',
  PO2 => 'Portal Second Age',
  PTK => 'Portal Three Kingdoms',
  UGL => 'Unglued',
  UNH => 'Unhinged',
  LEA => 'Limited Edition Alpha',
  Alpha => 'Limited Edition Alpha',
  LEB => 'Limited Edition Beta',
  Beta => 'Limited Edition Beta',
  "2ED" => 'Unlimited Edition',
  UNL => 'Unlimited Edition',
  "3ED" => 'Revised Edition',
  REV => 'Revised Edition',
  "4ED" => 'Fourth Edition',
  "5ED" => 'Fifth Edition',
  "6ED" => 'Classic Sixth Edition',
  "7ED" => 'Seventh Edition',
  "8ED" => 'Eighth Edition',
  "9ED" => 'Ninth Edition',
  "10E" => 'Tenth Edition',
  M10 => 'Magic 2010',
  M11 => 'Magic 2011',
  M12 => 'Magic 2012',
  M13 => 'Magic 2013',
  M14 => 'Magic 2014 Core Set',
  M15 => 'Magic 2015 Core Set',
  ORI => 'Magic Origins'
);

1;