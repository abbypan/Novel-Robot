#!/usr/bin/perl 
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Std;
use Novel::Robot;

$| = 1;

my %opt;
getopt( 'wsqkmt', \%opt );

my $xs = Novel::Robot->new(
    type => $opt{t} ? $opt{t} : 'html', 
    site => $opt{w} || $opt{s}, 
);

my $books_ref;
if($opt{w}){
    #writer
    my $writer_ref = $xs->{parser}->get_writer_ref($opt{w});
    $books_ref = $writer_ref->{booklist};
}elsif($opt{q}){
    #query
    my $type = decode( locale => $opt{q});
    my $keyword = decode( locale => $opt{k});
    $books_ref = $xs->{parser}->get_query_ref($type, $keyword);
}

my $select = $opt{m} ? $xs->select_book($books_ref) : $books_ref;
for my $r (@$select) {
    my $u = $r->{url};
    print "\rselect : $u\n";
    $xs->get_book($u);
} ## end for my $r (@$select)
