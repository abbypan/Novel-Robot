#!/usr/bin/perl
use utf8;
use Novel::Robot;
use Test::More ;
use Data::Dump qw/dump/;

my $xs = Novel::Robot->new();
$xs->set_parser('Nunu');
$xs->set_packer('TXT');


my $index_url = 'http://book.kanunu.org/files/youth/201104/2455.html';
my $chapter_url = "http://book.kanunu.org/files/youth/201104/2455/61068.html";
#$index_url = 'http://book.kanunu.org/book3/6823/index.html';
#$chapter_url = 'http://book.kanunu.org/book3/6823/130432.html';

my $index_ref = $xs->get_index_ref($index_url);
is($index_ref->{book}=~/^杉杉来吃/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '顾漫', 'writer');
is($index_ref->{chapter_num}, 20, 'chapter_num');
is($index_ref->{chapter_info}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}, '第一章', 'chapter_title');
is($chapter_ref->{content}=~/加班五天后/s ? 1 : 0, 1, 'chapter_content');

my $writer_url = 'http://book.kanunu.org/files/writer/183.html';
#$writer_url = 'http://book.kanunu.org/files/writer/6482.html';
my $writer_ref = $xs->get_writer_ref($writer_url);
is($writer_ref->{writer}, '古龙', 'writer_name');
my $cnt = grep { 
$_->{url} eq 'http://book.kanunu.org/book/4573/index.html' } 
@{$writer_ref->{booklist}};
is($cnt, 1, 'writer_book');

done_testing;
