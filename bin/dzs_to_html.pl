#!/usr/bin/perl
use strict;
use warnings;
use utf8;
$| = 1;

use Encode::Detect::CJK qw/detect/;
use Encode::Locale;
use Encode;
use File::Find::Rule;
use Getopt::Std;
use Novel::Robot::Packer::HTML;

my %opt;
getopt( 'wbfr', \%opt );
exit unless ( defined $opt{f} );

my @path = split ',', $opt{f};
my $r = parse_index(
    \@path, 
    writer        => decode(locale => $opt{w}), 
    book        => decode(locale=> $opt{b}), 
    chapter_regex => $opt{r} ? decode(locale=>$opt{r}) : undef, 
);
my $pk = Novel::Robot::Packer::HTML->new();
$pk->pack_book( $r );

sub parse_index {
    my ( $path, %opt ) = @_;
    $opt{chapter_regex} ||= get_default_chapter_regex();

    my %data;
    $data{writer}        = $opt{writer} || 'unknown';
    $data{book}          = $opt{book} || 'unknown';
    $data{index_url}   = '';

    my $p_ref = ref($path) eq 'ARRAY' ? $path : [$path];
    my $i = 1;
    for my $p (@$p_ref) {
        my @txts = sort File::Find::Rule->file()->in($p);
        for my $txt (@txts) {
            my $txt_data_ref = read_single_txt( $txt, \%opt );
            my $txt_file = decode( locale => $txt );
            for my $t (@$txt_data_ref) {
                $t->{id} = $i;
                $t->{url}    = $txt_file;
                $t->{writer} = $data{writer};
                $t->{book}   = $data{book};
                $t->{content} = format_chapter_content( $t->{content} );
                push @{ $data{chapter_info} }, $t;
                $i++;
            }
        }
    }
    $data{chapter_num} = $i;

    return \%data;
}

sub get_default_chapter_regex {
    #指定分割章节的正则表达式

    my $r_num =
    qr/[\d０１２３４５６７８９零○〇一二三四五六七八九十百千]+/;
    my $r_split = qr/[上中下]/;
    my $r_not_chap_head =
    qr/楔子|尾声|内容简介|正文|番外|终章|序言|后记|文案/;

    #第x章，卷x，第x章(大结局)，尾声x
    my $r_head  = qr/(卷|第|$r_not_chap_head)?/;
    my $r_tail  = qr/(章|卷|回|部|折)?/;
    my $r_post  = qr/([\s\-\(\/（]+.{0,35})?/;
    my $r_a = qr/(【?$r_head\s*$r_num\s*$r_tail$r_post】?)/;

    #(1)，(1)xxx，xxx(1)，xxx(1)yyy，(1-上|中|下)
    my $r_b_index = qr/[(（]$r_num[）)]/;
    my $r_b_tail  = qr/$r_b_index\s*\S+/;
    my $r_b_head  = qr/\S+\s*$r_b_index.{0,10}/;
    my $r_b_split = qr/[(（]$r_num[-－]$r_split[）)]/;
    my $r_b = qr/$r_b_head|$r_b_tail|$r_b_index|$r_b_split/;

    #1、xxx，一、xxx
    my $r_c = qr/$r_num[、.．].{0,10}/;

    #第x卷 xxx 第x章 xxx，第x卷/第x章 xxx
    my $r_d = qr/($r_a(\s+.{0,10})?){2}/;

    #后记 xxx
    my $r_e = qr/(【?$r_not_chap_head\s*$r_post】?)/;

    my $chap_r = qr/^\s*($r_a|$r_b|$r_c|$r_d|$r_e)\s*$/m;
    return $chap_r;
}

sub read_single_txt {
    my ( $txt, $opt ) = @_;

    my $charset = detect_file_charset($txt);
    open my $sh, "<:encoding($charset)", $txt;

    my @data;
    my ( $single_toc, $single_content ) = ( '', '' );

    #第一章
    while (<$sh>) {
        next unless /\S/;
        $single_toc = /$opt->{chapter_regex}/ ? $1 : $_;
        last;
    } ## end while (<$sh>)

    while (<$sh>) {
        next unless /\S/;
        if ( my ($new_single_toc) = /$opt->{chapter_regex}/ ) {
            if ( $single_toc =~ /\S/ and $single_content =~ /\S/s ) {
                push @data,
                { title => $single_toc, content => $single_content };
                $single_toc = '';
            } ## end if ( $single_toc =~ /\S/...)
            $single_toc .= $new_single_toc . "\n";
            $single_content = '';
        }
        else {
            $single_content .= $_;
        } ## end else [ if ( my ($new_single_toc...))]
    } ## end while (<$sh>)

    push @data, { title => $single_toc, content => $single_content };
    return \@data;
} ## end sub read_single_TXT

sub format_chapter_content {
    my ($c) = @_;
    for ($c) {
        s#<br\s*/?\s*>#\n#gi;
        s#\s*(.*\S)\s*#<p>$1</p>\n#gm;
        s#<p>\s*</p>##g;
    } ## end for ($chap_c)
    return $c;
}

sub detect_file_charset {
    my ($file) = @_;
    open my $fh, '<', $file;
    read $fh, my $text, 360;
    return detect($text);
} ## end sub detect_file_charset
