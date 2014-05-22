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

$xs->set_packer( 'WordPress') ;

my %packer_opt = (
    base_url => $opt{W},
    usr      => $opt{u},
    passwd   => $opt{p},
    tag => $opt{T} ? [ split ',', decode( locale => $opt{T} ) ] : undef, 
    category => $opt{c} ? [ split ',', decode( locale => $opt{c} ) ] : undef, 
    chapter_ids => $opt{i} ? $xs->split_id_list($opt{i}) : undef, 
);

if($opt{f}){
    $xs->set_parser('txt');
    my @path = split ',', $opt{f};
    my $r = $xs->{parser}->parse_index(\@path,
        writer => decode(locale => $opt{w}), 
        book => decode(locale =>$opt{b}),
        chapter_regex => $opt{r} ? decode( locale => $opt{r} ) : undef, 
    );
    $xs->{packer}->pack_book($r, \%packer_opt);
}else{
    my $index_url = $opt{b};
    $xs->set_parser($index_url);
    $xs->get_book($index_url, \%packer_opt);
}
