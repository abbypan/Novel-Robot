#!/usr/bin/perl 

=pod

=encoding utf8

=head1  DESC

下载小说，导入wordpress空间

=head1 EXAMPLE

    novel_to_wordpress.pl -b "http://www.dddbbb.net/html/18451/index.html" -c 言情 -w http://xxx.xxx.com  -u xxx -p xxx
    novel_to_wordpress.pl -b "http://www.jjwxc.net/onebook.php?novelid=2456" -c 原创 -w http://xxx.xxx.com  -u xxx -p xxx

=head1 USAGE

novel_to_wordpress.pl -b [index_url] -c [categories] -t [tags] -w [wordpress_url] -u [username] -p [password] 

=head1 OPTIONS

-b : book url，小说目录页，例如 http://www.jjwxc.net/onebook.php?novelid=2456

-c : categories，小说类别，例如 原创

-t : tags，标签，例如 顾漫

-w : wordpress 地址

-u : wordpress 用户

-p : wordpress 密码

-h : help 帮助

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
getopt( 'bctiwuph', \%opt );

print_usage() if ( exists $opt{h} );

my $xs = Novel::Robot->new();

my $index_url = $opt{b};
$xs->set_parser($index_url);

my %packer_opt = (
    'base_url' => $opt{w},
    'usr'      => $opt{u},
    'passwd'   => $opt{p},
);
$packer_opt{tag}      = decode( locale => $opt{t} ) if ( $opt{t} );
$packer_opt{category} = decode( locale => $opt{c} ) if ( $opt{c} );

#$opt{i} 暂时废弃

$xs->set_packer( 'WordPress', \%packer_opt );
$xs->get_book($index_url);

sub print_usage {
    print <<"USAGE";
[USAGE]

$0 -b "http://www.jjwxc.net/onebook.php?novelid=2456" -c 原创 -w "http://www.xxx.com" -u xxx -p xxx

[OPTION]
-b : book url，小说目录页，例如 http://www.jjwxc.net/onebook.php?novelid=2456
-c : categories，小说类别，例如 原创
-t : tags，标签，例如 顾漫
-w : wordpress 地址
-u : wordpress 用户
-p : wordpress 密码
-h : help 帮助
USAGE
    exit;

    #-i : chapter ids，章节序号，例如 1,4-7,10
} ## end sub print_usage
