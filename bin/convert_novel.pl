#!/usr/bin/perl 
use strict;
use warnings;
use Encode;
use Encode::Locale;
use Digest::MD5 qw/md5_base64/;
use Getopt::Std;
use POSIX qw/strftime/;
use utf8;
$|=1;
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

my %opt;
getopt( 'ftcTo', \%opt );
$opt{t} ||= 'mobi';

novel_to_any($opt{f}, $opt{t});


sub novel_to_any {
    my ($f, $type) = @_;

    $type ||='mobi';
    my $dst_file = $f;
    $dst_file=~s/[a-z0-9]+$/$type/;

    my ($writer,$book) = $f=~/([^\\\/]+?)-(.+?)\.[^.]+$/;
    my %convert_opt = (
        'authors'=>$writer , 
        'title'=>$book , 
        'chapter-mark'=>"none" , 
        'page-breaks-before'=>"/" , 
        'max-toc-links'=>0, 
    );

    my $convert_opt_str = join(" ", map { qq[--$_ "$convert_opt{$_}"] } keys(%convert_opt) );
    system(qq[ebook-convert "$f" "$dst_file" $convert_opt_str]);
}
