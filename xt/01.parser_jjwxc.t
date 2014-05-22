#!/usr/bin/perl
use utf8;
use lib '../Novel-Robot/lib';
use Novel::Robot;
use Test::More ;
use Data::Dump qw/dump/;

my $xs = Novel::Robot::Parser->new(site=>'Jjwxc');


my $u = 'http://www.jjwxc.net/onebook.php?novelid=2530';
my $xx = Novel::Robot->new(site => $u, type => 'html');
#my $r = $xx->get_book($u, output_scalar=>1);
my ($r, $x) = $xx->get_book($u, output_scalar=>1);
#print ref($r);
dump($x);
exit;

#my $x = $xs->get_index_ref('http://www.jjwxc.net/onebook.php?novelid=1945417');
#use Encode;
#print encode('cp936', "writer:$x->{writer},book: $x->{book}\n");
#exit;

my $index_url = 'http://www.jjwxc.net/onebook.php?novelid=2456';
my $chapter_url = "$index_url&chapterid=1";

my $index_ref = $xs->get_index_ref($index_url);
is($index_ref->{book}=~/^何以笙箫默/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '顾漫', 'writer');
is($index_ref->{chapter_num}, 16, 'chapter_num');
is($index_ref->{chapter_info}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}, '第一章', 'chapter_title');
is($chapter_ref->{content}=~/默笙/s ? 1 : 0, 1, 'chapter_content');


my $writer_url = "http://www.jjwxc.net/oneauthor.php?authorid=3243";
my $writer_ref = $xs->get_writer_ref($writer_url);
is($writer_ref->{writer}, '顾漫', 'writer_name');
my $cnt = grep { $_->{url} eq $index_url } @{$writer_ref->{booklist}};
is($cnt, 1, 'writer_book');

my $query_ref = $xs->get_query_ref('作者', '顾漫');
my $cnt = grep { $_->{url} eq $index_url } @$query_ref;
is($cnt, 1, 'query_writer');


done_testing;
