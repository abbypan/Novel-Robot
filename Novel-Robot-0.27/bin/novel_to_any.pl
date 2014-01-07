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
getopt( 'wsqvmt', \%opt );

my $xs = Novel::Robot->new();
$xs->set_packer($opt{t} || 'TXT');
$xs->set_parser($opt{w} || $opt{s});

my $books_ref;
if($opt{w}){
    #writer
    my $writer_ref = $xs->{parser}->get_writer_ref($opt{w});
    $books_ref = $writer_ref->{booklist};
}elsif($opt{q}){
    #query
    my $keyword = decode( locale => $opt{q});
    my $value = decode( locale => $opt{v});
    $books_ref = $xs->{parser}->get_query_ref($keyword, $value);
}

my $select = $opt{m} ? $xs->select_book($books_ref) : $books_ref;
for my $r (@$select) {
    my $u = $r->{url};
    print "\rselect : $u\n";
    $xs->get_book($u);
} ## end for my $r (@$select)
