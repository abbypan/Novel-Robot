#!/usr/bin/perl 
# require :  txt2epub https://github.com/abbypan/txt2epub
use strict;
use warnings;
use File::Slurp qw/slurp/;
use Cwd;
my $cwd = getcwd;

my ($f) = @ARGV;

my ($writer,$book) = $f=~/([^\\\/].*?)-(.+?).txt/;

my $s = slurp($f);
my @data =split /chap \d+ : /s, $s;

my $dir = int(rand(99999999))."-$$";
mkdir($dir);
chdir($dir);

for my $i ( 1 .. $#data){
    my $j = sprintf("%03d.txt", $i);
    open my $fh, '>', $j;
    print $fh $data[$i];
    close $fh;
}

my $epub = $f;
$epub=~s/.txt/.epub/;
system(qq/txt2epub --title $book --creator $writer  "$epub" [0-9]*.txt/);
chdir($cwd);
`mv $dir/*.epub .`;
`rm -r $dir`;
