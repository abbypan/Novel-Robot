#!/usr/bin/perl 
use strict;
use warnings;
use utf8;

use Getopt::Std;
use Encode::Locale;
use Encode;

use Novel::Robot;

$| = 1;

my %opt;
getopt( 'Wborctwup', \%opt );

my $xs = Novel::Robot->new();
$xs->set_parser('TXT');

my $chap_regex = $opt{r};
$xs->{parser}{chapter_regex} = decode( locale => $chap_regex ) if($chap_regex);

my %packer_opt = (
    'base_url' => $opt{w},
    'usr'      => $opt{u},
    'passwd'   => $opt{p},
);
$packer_opt{tag}      = decode( locale => $opt{t} ) if ( $opt{t} );
$packer_opt{category} = decode( locale => $opt{c} ) if ( $opt{c} );
$xs->set_packer( 'WordPress', \%packer_opt );

my $writer = $opt{W};
my $book = $opt{b};
my @path = split ',', $opt{o};
$xs->get_book({ writer => $writer, book => $book, path => \@path  });
