#!/usr/bin/perl
use utf8;
use Novel::Robot;
use Test::More ;
use Data::Dump qw/dump/;

my $xs = Novel::Robot->new();
$xs->set_parser('Dddbbb');
$xs->set_packer('HTML');

my $index_url = 'http://www.dddbbb.net/html/10678/index.html';
my $chapter_url = "http://www.dddbbb.net/10678_569905.html";

#$index_url = 'http://www.dddbbb.net/html2/90731/index.html';
#my $index_ref = $xs->get_index_ref($index_url);
#dump($index_ref);exit;
#$chapter_url = 'http://www.dddbbb.net/90731_5169364.html';
#my $chapter_ref = $xs->get_chapter_ref($chapter_url);
#dump($chapter_ref);exit;

my $index_ref = $xs->get_index_ref($index_url);
is($index_ref->{book}=~/^拼图/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '凌淑芬', 'writer');
is($index_ref->{chapter_num}, 14, 'chapter_num');
is($index_ref->{chapter_info}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}, '序', 'chapter_title');
is($chapter_ref->{content}=~/几许/s ? 1 : 0, 1, 'chapter_content');

my $writer_url = "http://www.dddbbb.net/html/author/2373.html";
my $writer_ref = $xs->get_writer_ref($writer_url);
is($writer_ref->{writer}, '凌淑芬', 'writer_name');
my $cnt = grep { $_->{book} eq '拼图' } @{$writer_ref->{booklist}};
is($cnt, 1, 'writer_book');

my $query_ref = $xs->get_query_ref('作品', '拼图');
my $cnt = grep { $_->{url} eq $index_url } @$query_ref;
is($cnt, 1, 'query_book');

done_testing;
