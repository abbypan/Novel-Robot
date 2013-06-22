#!/usr/bin/perl 

=pod

=encoding utf8

=head1 DESC

    简单的电子书工具，支持将TXT转换成HTML   

=head1 EXAMPLE

    dzs_to_html.pl -w 顾漫 -b 何以笙箫默 -o hy1.txt

    dzs_to_html.pl -w 顾漫 -b 何以笙箫默 -o hy1.txt,hy2.txt,dir1 -r "第[ \\t\\d]+章"
    
=head1 USAGE

    dzs_to_html.pl -w [作者] -b [书名] -o [TXT文件或目录] -r [章节标题匹配的正则式]

=head1 OPTIONS

    -w：指定作者名

    -b: 指定书名

    -o: 指定文本来源(可以是单个目录或文件)

    -r: 指定分割章节的正则表达式(例如："第[ \\t\\d]+章")

=cut


use strict;
use warnings;

use utf8;

use Getopt::Std;
use Encode::Locale;
use Encode;
use Novel::Robot;

use vars qw/$writer $book $obj $chap_regex/;

#不缓冲直接输出
$| = 1;

#本地编码处理
binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

my %opt;
getopt( 'wbor', \%opt );

( $writer, $book, $obj, $chap_regex ) = @opt{ 'w', 'b', 'o', 'r' };
exit unless ( defined $obj );

my $xs = Novel::Robot->new();
$xs->set_packer('HTML');
$xs->set_parser('TXT');
$xs->{parser}{chapter_regex} = decode( locale => $chap_regex ) if($chap_regex);

my @path = split ',', $obj;

$xs->get_book({ writer => $writer, book => $book, path => \@path  });
