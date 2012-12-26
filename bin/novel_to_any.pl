#!/usr/bin/perl 
=pod

=encoding utf8

=head1 DESC

TERM下面选择下载小说

=head1 EXAMPLE

    novel_to_any.pl -w "http://www.jjwxc.net/oneauthor.php?authorid=3243" -m 1 -t "novel_to_html.pl {url}"

    novel_to_any.pl -s Jjwxc -o "作品 何以笙箫默" -m 1 -t "novel_to_html.pl {url}"
    
=head1 USAGE

novel_to_any.pl -w [writer_url] -o [writer_url option] -m [select_menu_or_not] -t [novel_save_cmd]

novel_to_any.pl -s [site] -o [query_detail] -m [select_menu_or_not] -t [novel_save_cmd]

=head1 OPTIONS

-w : 作者专栏URL

-s : 指定查询的站点

-o : 获取作者专栏的补充参数(可选) 或者 查询的具体信息(必选)

-m : 是否输出小说选择菜单

-t : 小说保存指令，URL信息以 {url} 指定

=cut
use strict;
use warnings;
use utf8;
use JSON;
use Encode::Locale;
use Encode;
use Term::Menus;

use Getopt::Std;

$| = 1;

my %opt;
getopt( 'wsomt', \%opt );
#w : writer
#s(query) : site
#o : writer option / query info
#m : select menu
#t : to txt / to html / to wordpress ...

my $cmd = $opt{w} ? qq[novel_writer_to_json.pl $opt{w} $opt{o}] : qq[novel_query_to_json.pl $opt{s} $opt{o}];
print $cmd;
my $json = `$cmd`;
my $info = decode_json( $json );

my $select = $opt{m} ? select_book($info) : $info; 
print $_->[2],"\n" for @$select;
for my $r (@$select){
    my $u = $r->[2];
    my $c = $opt{t};
    $c=~s/{url}/$u/;
    system($c);
}

sub select_book {
    my ($info_ref ) = @_;

    my %menu = ( 'Select' => 'Many', 'Banner' => 'Book List', );

    #菜单项，不搞层次了，恩
    my %select;
    my $i = 1;
    for my $r (@$info_ref) {
        my ( $info, $key, $url ) = @$r;
        my $item = "$info --- $key";
        $select{$item} = $url;
        $item = encode( locale => $item );
        $menu{"Item_$i"} = { Text => $item };
        $i++;
    } ## end for my $r (@$info_ref)

    #最后选出来的小说
    my @select_result;
    for my $item ( &Menu( \%menu ) ) {
        $item = decode( locale => $item );
        my ( $info, $key ) = ( $item =~ /^(.*) --- (.*)$/ );
        push @select_result, [ $info, $key, $select{$item} ];
    }

    return \@select_result;

} ## end sub select_book
