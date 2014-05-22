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
getopt( 'btCSn', \%opt );

my $xs = Novel::Robot->new(
    type => $opt{t} ? $opt{t} : 'html', 
    site => $opt{b} ,
);
$opt{C} //=1;
$opt{S} //=1;

my ($m, $n)=(1, undef);

my $info = $xs->{parser}->get_index_ref($opt{b});
my $num = $info->{chapter_num};

use POSIX qw/ceil/;
my $en = ceil(log($num+1)/log(10));

for(my $m = 1; $m<=$num; $m+=$opt{n}){
    my $n = $m+$opt{n}-1;
    $n = $num if($n>$num);
    my $out = sprintf("%s-%s-%0${en}d.%s", 
        $info->{writer}, $info->{book}, 
        $n, $xs->{packer}->suffix());

    $xs->get_book($opt{b}, 
        min_chapter => $m, 
        max_chapter => $n, 
        with_toc => $opt{C}, 
        show_progress_bar => $opt{S}, 
        output => encode(locale=>$out), 
        title => sprintf("%s 《%s》 %0${en}d", 
                    $info->{writer}, $info->{book}, $n),
    );

}

