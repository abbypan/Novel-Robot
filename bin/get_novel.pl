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
getopt( 'wbfrtiCSoTcR', \%opt );

my $xs = Novel::Robot->new(
    type => $opt{t} ? $opt{t} : 'html', 
    site => $opt{f} ? 'txt' : $opt{b} ,
);
$opt{C} //=1;
$opt{S} //=1;

my ($m, $n);
if($opt{i}){
    ($m, $n) = split '-', $opt{i};
}

if($opt{f}){
    my @path = split ',', $opt{f};
    my $r = $xs->{parser}->parse_index(\@path,
        writer => decode(locale => $opt{w}), 
        book => decode(locale =>$opt{b}),
        chapter_regex => $opt{r} ? decode( locale => $opt{r} ) : undef, 

        tag => $opt{T} ? [ split ',', decode( locale => $opt{T} ) ] : undef,
        category => $opt{c} ? [ split ',', decode( locale => $opt{c} ) ] : undef, 
        remark => $opt{R} ? decode( locale => $opt{R} ) : undef, 
    );
    $xs->{packer}->main($r);
}else{
    $xs->get_book($opt{b}, 
        min_chapter => $m, 
        max_chapter => $n, 
        with_toc => $opt{C}, 
        show_progress_bar => $opt{S}, 
        output => $opt{o}, 

        tag => $opt{T} ? [ split ',', decode( locale => $opt{T} ) ] : undef,
        category => $opt{c} ? [ split ',', decode( locale => $opt{c} ) ] : undef, 
        remark => $opt{R} ? decode( locale => $opt{R} ) : undef, 
    );
}
