#!/usr/bin/perl 
use strict;
use warnings;
use Encode;
use Encode::Locale;
use Digest::MD5 qw/md5_base64/;
use Getopt::Std;
use POSIX qw/strftime/;
use utf8;

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

    system(qq[ebook-convert "$f" "$dst_file" --authors "$writer" --title "$book" --chapter-mark "none" --page-breaks-before "/" --max-toc-links 0]);
}


