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
getopt( 'wfrbcTWupi', \%opt );


my $xs = Novel::Robot->new();

my %packer_opt = (
    'base_url' => $opt{W},
    'usr'      => $opt{u},
    'passwd'   => $opt{p},
);
$packer_opt{tag}      = decode( locale => $opt{T} ) if ( $opt{T} );
$packer_opt{category} = decode( locale => $opt{c} ) if ( $opt{c} );
$packer_opt{chapter_ids} = $xs->split_id_list($opt{i}) if ( $opt{i} );
$xs->set_packer( 'WordPress', \%packer_opt );

if($opt{f}){
    $xs->set_parser('TXT');
    my $chap_regex = $opt{r};
    $xs->{parser}{chapter_regex} = decode( locale => $chap_regex ) if($chap_regex);
    my @path = split ',', $opt{f};
    $xs->get_book({ writer => $opt{w}, book => $opt{b}, path => \@path });
}else{
    my $index_url = $opt{b};
    $xs->set_parser($index_url);
    $xs->get_book($index_url, \%packer_opt);
}
