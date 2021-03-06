Magic: The Gathering and Dice Masters collection data source scripts for Tellico
========================================================================
<https://github.com/tomaszg7/tellico_stuff>


The Magic the Gathering script grabs information from 
http://gatherer.wizards.com. It is rather ugly regexp job since the Gatherer 
doesn't support (as far as I know it) any API. So, it is sure to break in the 
future when they change the layout of their webpage (or even refactor their 
html).

Right now it supports searching the online database by card name, artist name 
and "multiverse id". It grabs all data I could think of (including card image) 
and stores it in collection. If you can't find a card by name, you can try to 
locate it on-line and add to collection using its Gatherer id (multiverse id). 
You can also make decks using Tellico's loan feature.

Sample screenshot of a demo collection: 
<http://tomaszg.pl/tellico-mtg/screenshot.jpg>

Requirements:
-------------
1. Perl
2. Perl modules: `Getopt::Std`, `File::Fetch`, `MIME::Base64`, `File::Copy`, `Storable` 
3. (optional) `Archive::Zip` for some helper scripts

Installation:
-------------
Put the file `mtg2.pl` in Tellico datasource directory (or anywhere else) and 
`mtg*.pm` files where Perl can find them. You can check `@INC` paths via:

```perl -e "print @INC"```

You need to add a new datasource for "Custom Collection" configuring Tellico 
(see screenshot: <http://tomaszg.pl/tellico-mtg/config.jpg>):

1. Collection type: Custom
2. Result type: Tellico
3. Check:
	* "Title": `-n %1`
	* "Person": `-a %1`
	* "arXiv id": `-N %1`
	* "Update": `-N %{multiverseid}`

I don't think it's possible to make arbitrary labels for search fields, so 
"title" means card's name, "person" means artist and "arxiv id" denotes 
Gatherer's "multiverse id".

Create empty collection of "custom" type and just use datasource to look for 
the cards. It prints out only 10 first results, so you might need to search 
some by multiverse id.

The scripts caches search results and images in `~/.cache/mtg-perl`.

Helper scripts:
---------------
* `mtg-braki.pl` - reads Tellico database files listed in `mtg_bases.pm` and prints out missing cards for a 
		given expansion(s) and/or some stats, including prices
* `mtg-check-pseudo.pl` - reads Tellico databases and checks if there are some 
		"pseudocards" listed there. At the moment it only looks for cards  listed by hand in `mtg_pseudo.pm`
* `mtg-set.pl` - generates a Tellico database containing whole expansion
* `mtg-parse-decklist.pl` - generates a Tellico database based on a decklist file (each line containing number and card_name, numbers are ignored at the moment)
* `mtg-prices.pl` - calculates value of collection according to "trend price" from <http://www.cardmarket.com>

Some scripts have hardcoded locations of input/output files, so they might need 
hand-tuning.

Dice Masters:
-------------

Dice Masters support requires an extra SQLite database file since I couldn't 
find reliable online source. I got the file from Android app "Transition zone" 
but due to licensing issues I don't think I can upload it. If anyone would be 
interested, I can try to contact author of the app and ask for permission. 
