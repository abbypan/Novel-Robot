#!/usr/bin/perl
use utf8;
use Novel::Robot;
use Test::More ;
use Data::Dump qw/dump/;

my $xs = Novel::Robot->new(
    site=> 'Dingdian',
    type => 'html', 
);

my $index_url = 'http://www.23us.com/html/0/202/';
my $chapter_url = 'http://www.23us.com/html/0/202/15973286.html';

my $index_ref = $xs->{parser}->get_index_ref($index_url);
is($index_ref->{book}=~/^全职高手/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '蝴蝶蓝', 'writer');
is($index_ref->{chapter_info}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->{parser}->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/被驱逐的高手/?1:0, 1 , 'chapter_title');



done_testing;
