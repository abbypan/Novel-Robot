#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Encode qw(decode);
use File::Copy qw(copy);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

my $root = File::Spec->catdir( $FindBin::RealBin, '..' );
my $tmp = tempdir( CLEANUP => 1 );
my $input = File::Spec->catfile( $tmp, '牵机-断情逐妖记.txt' );
my $output = File::Spec->catfile( $tmp, '牵机-断情逐妖记.html' );

copy( File::Spec->catfile( $FindBin::RealBin, 'novel-utf8.txt' ), $input )
    or die "copy fixture: $!";

my $bin = File::Spec->catfile( $root, 'bin', 'novel-robot' );
my $exit = system {
    $^X
} $^X, $bin, '-s', 'txt', '-f', $input, '-t', 'html', '-o', $output;

is( $exit, 0, 'CLI accepts a Chinese input filename' );
ok( -s $output, 'CLI creates the requested Chinese output filename' );

open my $fh, '<:raw', $output or die "open output: $!";
local $/;
my $html = decode( 'UTF-8', <$fh> );

like(
    $html,
    qr{<meta property="opf\.authors" content="牵机">},
    'derive a Unicode writer from the filename',
);
like(
    $html,
    qr{<meta property="opf\.titlesort" content="断情逐妖记">},
    'derive a Unicode book title from the filename',
);
like( $html, qr{中国}, 'preserve Unicode chapter content' );

done_testing;
