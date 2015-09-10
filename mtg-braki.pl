#!/usr/bin/env perl
use MIME::Base64 qw(encode_base64);
use Getopt::Std;
use File::Fetch;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

$surl= 'http://gatherer.wizards.com/Pages/Search/Default.aspx?';

sub search_wyniki {
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

 	      $lista{ $id } = $nm." ".$r;
# 	      print $nm." ".$r;
	}
#    push @lista ,  /multiverseid=(\d+)[\'\"]/g;
    }
}
} # sub search_wyniki

sub build_checklist {
$sstr = $opts{'n'};
$sstr =~ s/\s+/+/g;
$sstr = "set=[\"".$sstr."\"]"; #output=checklist&

my $ff = File::Fetch->new(uri => $surl.$sstr);
my $where = $ff->fetch(to => '/tmp') or die $ff->error;;

open $wyniki, $where;

my @strony; my $str_no;

while (<$wyniki>) {
    $str_no = push @strony ,  /Default\.aspx\?page=(\d+)&/g;
}

seek ($wyniki, 0, 0);
search_wyniki;
close $wyniki;

$str_no=($str_no-4)/2;

# print $str_no;

foreach $i (1..$str_no)
{
    my $ff = File::Fetch->new(uri => $surl.$sstr."&page=$i");
    my $where = $ff->fetch(to => '/tmp') or die $ff->error;;

    open $wyniki, $where;
    search_wyniki;
    close $wyniki;

}

} #sub build_checklist

sub build_base {

my $baza = Archive::Zip->new();
   unless ( $baza->read( '../../mtg.tc' ) == AZ_OK ) {
       die 'read error';
   }
foreach (split(/\n/,$baza->contents( "tellico.xml" ))) {
      $_ =~ /<multiverseid>(\d+)<\/multiverseid>/g || next;
      $karty{ $1 } = "1";
}

} # sub build_base

getopt('n', \%opts);

if (!$opts{'n'}) { die "-n - search by expantion.\n";}

%lista = ();

build_checklist;

#     $,="\n";
#     print sort(values %lista);


%karty = ();

build_base;

# print (keys %karty)."\n";

@brak;

$j=0;

foreach $i (keys %lista) {
   unless (exists $karty{ $i }) {
       print $lista{ $i }."\n";
       $j++;
   }
}

print $j." cards missing.\n";