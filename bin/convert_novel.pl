#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use Encode qw/:all/;
use Encode::Locale;
use Getopt::Std;
$|=1;
#binmode(STDIN, ":encoding(console_out)");
#binmode(STDOUT, ":encoding(console_out)");
#binmode(STDERR, ":encoding(console_out)");

my %opt;
getopt( 'ftwb', \%opt );
$opt{t} ||= 'mobi';

my $dst_file = $opt{f};
$dst_file=~s/[a-z0-9]+$/$opt{t}/i;

my ($writer,$book) = $opt{f}=~/([^\\\/]+?)-(.+?)\.[^.]+$/;
my %conv = (
    'authors'=> $opt{w} || $writer , 
    'title'=> $opt{b} || $book , 
    'chapter-mark'=>"none" , 
    'page-breaks-before'=>"/" , 
    'max-toc-links'=>0, 
);

my $conv_str = join(" ", map { qq[--$_ "$conv{$_}"] } keys(%conv) );
my $cmd=qq[ebook-convert "$opt{f}" "$dst_file" $conv_str]; 
system($cmd);
