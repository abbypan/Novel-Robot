#!/usr/bin/perl
use utf8;
use Novel::Robot;
use Test::More ;
use Data::Dump qw/dump/;

my $xs = Novel::Robot->new();
$xs->set_parser('Shunong');
$xs->set_packer('HTML');

my $index_url = 'http://www.shunong.com/yuedu/1/1235/index.html';
my $chapter_url = "http://www.shunong.com/yuedu/1/1235/67607.html";

my $index_ref = $xs->get_index_ref($index_url);
is($index_ref->{book}=~/^何以笙箫默/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '顾漫', 'writer');
is($index_ref->{chapter_num}, 15, 'chapter_num');
is($index_ref->{chapter_info}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}, '序 言', 'chapter_title');
is($chapter_ref->{content}=~/顾快/s ? 1 : 0, 1, 'chapter_content');

done_testing;
