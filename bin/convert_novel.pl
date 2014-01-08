#!/usr/bin/perl 
# require :  http://www.calibre-ebook.com/
use strict;
use warnings;

my ($f, $type) = @ARGV;
$type ||='mobi';

my $dst_file = $f;
$dst_file=~s/[a-z0-9]+$/$type/;

my ($writer,$book) = $f=~/([^\\\/]+?)-(.+?)\.[^.]+$/;

`ebook-convert "$f" "$dst_file" --authors "$writer" --title "$book"`;
