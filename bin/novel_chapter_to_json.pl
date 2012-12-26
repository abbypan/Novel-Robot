#!/usr/bin/perl 
=pod

=encoding utf8

=head1  ABSTRACT

获取小说章节页信息，以JSON格式输出

=head1 EXAMPLE

    novel_chapter_to_json.pl "http://www.jjwxc.net/onebook.php?novelid=2456&chapterid=2" 2

=head1 USAGE

novel_chapter_to_json.pl [chapter_url] [chapter_id]

=cut

use strict;
use warnings;
use utf8;
use JSON;



use Novel::Robot;

my ($chapter_url, $id) = @ARGV;

my $xs = Novel::Robot->new();
my $chapter_ref = $xs->get_chapter_ref($chapter_url, $id);
exit unless($chapter_ref);

my $chapter_json = encode_json $chapter_ref;
print $chapter_json;
