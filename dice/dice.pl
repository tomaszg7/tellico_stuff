#!/usr/bin/env perl
use DBI;

use Getopt::Std;
use dice;

getopt('n', \%opts);

unless ($opts{'n'}) {die "-n - search by name.\n"};

my $sstr = "%".$opts{'n'}."%";
$base = $ENV{"HOME"}."/.cache/mtg_perl/dicedb.sqlite";

my $dbh = DBI->connect("dbi:SQLite:dbname=".$base,"","");

my $sql = 'SELECT Universe, CardSet, CharName, CardName, CardImage, Cost, AffiliationOne, AffiliationTwo,
AffiliationThree, Energy, Rarity, MaxDice FROM tblCards WHERE CharName like ? OR CardName like ?';
my $sth = $dbh->prepare($sql);
$sth->execute($sstr,$sstr);


print dice::header;

$i=0;

while (my $row = $sth->fetchrow_hashref)
  {
    print dice::entry $row, $i;
    $i++;
  }
print '</collection></tellico>';

