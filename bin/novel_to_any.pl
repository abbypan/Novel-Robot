#!/usr/bin/perl 

=pod

=encoding utf8

=head1 DESC

    TERM下面选择下载小说

=head1 EXAMPLE

    novel_to_any.pl -w "http://www.jjwxc.net/oneauthor.php?authorid=3243" -m 1 -t HTML

    novel_to_any.pl -s Jjwxc -q 作品 -v 何以笙箫默 -m 1 -t HTML
    
=head1 USAGE

    novel_to_any.pl -w [writer_url] -m [select_menu_or_not] -t [packer_type]

    novel_to_any.pl -s [site] -q [query_keyword] -v [query_value] -m [select_menu_or_not] -t [packer_type]

=head1 OPTIONS

    -w : 作者专栏URL

    -s : 指定查询的站点
    -q : 查询的类型
    -v : 查询的关键字

    -m : 是否输出小说选择菜单

    -t : 小说保存类型，例如TXT/HTML

=cut

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
