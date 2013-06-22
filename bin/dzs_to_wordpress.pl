#!/usr/bin/perl 

=pod

=encoding utf8

=head1  DESC

    将TXT导入wordpress空间

=head1 EXAMPLE

    dzs_to_wordpress.pl -W 顾漫 -b 何以笙箫默 -o hy.txt -c 言情 -w http://xxx.xxx.com  -u xxx -p xxx

=head1 OPTIONS

-W : writer name，作者名

-b : book name，书名

-o: 指定文本来源(可以是单个目录或文件)

-r: 指定分割章节的正则表达式(例如："第[ \\t\\d]+章")

-c : categories，小说类别，例如 原创

-t : tags，标签，例如 顾漫

-w : wordpress 地址

-u : wordpress 用户

-p : wordpress 密码

=cut

#-i : chapter ids，章节序号，例如 1,4-7,10

use strict;
use warnings;
use utf8;

use Getopt::Std;
use Encode::Locale;
use Encode;

use Novel::Robot;

$| = 1;

my %opt;
getopt( 'Wborctwup', \%opt );

my $xs = Novel::Robot->new();
$xs->set_parser('TXT');

my $chap_regex = $opt{r};
$xs->{parser}{chapter_regex} = decode( locale => $chap_regex ) if($chap_regex);

my %packer_opt = (
    'base_url' => $opt{w},
    'usr'      => $opt{u},
    'passwd'   => $opt{p},
);
$packer_opt{tag}      = decode( locale => $opt{t} ) if ( $opt{t} );
$packer_opt{category} = decode( locale => $opt{c} ) if ( $opt{c} );
$xs->set_packer( 'WordPress', \%packer_opt );

my $writer = $opt{W};
my $book = $opt{b};
my @path = split ',', $opt{o};
$xs->get_book({ writer => $writer, book => $book, path => \@path  });
