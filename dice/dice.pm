package dice;

#use MIME::Base64 qw(encode_base64);
use File::Copy;
use Storable;


$img_dir = $ENV{"HOME"}."/.cache/mtg_perl/dice_cards";


sub entry {
    my $entry = $_[0];
    my $i =  $_[1];
    my %entry;

# get rid of & in D&D
$entry->{Universe} =~ s/\&/&amp;/;
$entry->{Energy} =~ s/lightning/bolt/;

return <<ENTRY;
<entry id="$i">
   <card-name>$entry->{CharName}</card-name>
   <title>$entry->{CardName}</title>
   <cost>$cost{ $entry->{Cost} }</cost>
   <type>$entry->{Energy}</type>
   <affiliations>
    <affiliation>$aff{ $entry->{AffiliationOne} }</affiliation>
    <affiliation>$aff{ $entry->{AffiliationTwo} }</affiliation>
    <affiliation>$aff{ $entry->{AffiliationThree} }</affiliation>
   </affiliations>
   <set>$exp{ $entry->{CardSet} }</set>
   <universe>$entry->{Universe}</universe>
   <rarity>$rar{ $entry->{Rarity} }</rarity>
   <die-limit>$entry->{MaxDice}</die-limit>
   <picture>$img_dir/$entry->{CardImage}.jpg</picture>
</entry>
ENTRY

#missing fields
#   <collector-number></collector-number>
#   <text>$entry{text}</text>

} #sub entry

sub header {
return <<HEAD;
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE tellico PUBLIC "-//Robby Stephenson/DTD Tellico V11.0//EN" "http://periapsis.org/tellico/dtd/v11/tellico.dtd"><tellico xmlns="http://periapsis.org/tellico/" syntaxVersion="11">
<collection title="My Collection" type="1">
<fields>
   <field title="Card Name" flags="2" category="General" format="4" description="New Field 1" type="1" name="card-name"/>
   <field title="Card Subtitle" flags="0" category="General" format="1" description="Title" type="1" name="title"/>
   <field title="Collector Number" flags="0" category="General" format="4" description="New Field 2" type="6" name="collector-number"/>
   <field title="Cost" flags="0" category="General" format="4" description="New Field 3" type="6" name="cost"/>
   <field title="Type" flags="2" category="General" format="4" description="New Field 4" type="3" allowed="bolt;fist;mask;shield" name="type"/>
   <field title="Affiliation" flags="7" category="General" format="4" description="New Field 5" type="1" name="affiliation"/>
   <field title="Text" flags="0" category="Text" format="4" description="New Field 6" type="2" name="text"/>
   <field title="Rarity" flags="6" category="General" format="4" description="New Field 7" type="1" name="rarity"/>
   <field title="Universe" flags="6" category="General" format="4" description="New Field 7" type="1" name="universe"/>
   <field title="Expansion" flags="6" category="General" format="4" description="New Field 7" type="1" name="set"/>
   <field title="Die limit" flags="0" category="General" format="4" description="New Field 8" type="6" name="die-limit"/>
   <field title="Picture" flags="0" category="Picture" format="4" description="New Field 9" type="10" name="picture"/>
</fields>
HEAD
}

%rar = (
  as => 'Starter',
  bc => 'Common',
  cu => 'Uncommon',
  dr => 'Rare',
  esr => 'Mythic',
  gp => 'Promo',
  halt => 'Promo',
  fz => 'Promo'
);

%cost = (
  one => 1,
  two => 2,
  three => 3,
  four => 4,
  five => 5,
  six => 6,
  seven => 7,
  eight => 8,
  nine => 9,
  ten => 10,
);

%aff = (
  avengers => "Avengers",
  xmen => "X-Men",
  hydra => "Villain",
  fanfour => "Fantastic Four",
  blank => "",
  force => "Phoenix Force",
  foot => "Foot",
  egypt => "Egypt",
  neutral => "Neutral",
  evil => "Evil",
  good => "Good",
  league => "Justice League",
  society => "Justice Society",
  legion => "Legion of Supervillains",
  villain => "Villain",
  crime => "Crime Syndicate",
  titans => "Teen Titans",
  zombieorg => "Zombie",
  guardians => "Guardians of the Galaxy",
  shieldorg => "S.H.I.E.L.D.",
  indigotribeorg => "Indigo Tribe",
  sinestrocorps => "Sinestro Corps",
  blacklanterncorps => "Black Lantern Corps",
  starsapphirecorps => "Star Sapphire Corps",
  redlanterncorps => "Red Lantern Corps",
  greenlanterncorps => "Green Lantern Corps",
  bluelanterncorps => "Blue Lantern Corps",
  orangelanterncorps => "Orange Lantern Corps", 
  spiderfriends => "Spider Friends",
  sinistersix => "Sinister Six",
  monster => "Monster",
  emeraldenclave => "Emerald Enclave",
  orderofthegauntlet => "Order of the Gauntlet",
  lordsalliance => "Lords Alliance",
  harpers => "Harpers",
  zhentarim => "Zhentarim",
  icecream => "Energy Conduit",
);

%exp = (
  AVX => 'Avengers vs X-Men',
  UX => 'Uncanny X-Men',
  S1 => 'Yu-Gi-Oh! Series One',
  BFF => 'Battle for Faer&#251;n',
  JL => 'Justice League',
  AoU => 'Age of Ultron',
  WoL => 'War of Light',
  ASM => 'The Amazing Spider-Man',
);

1;