#!/usr/bin/perl 
use strict;
use warnings;

use utf8;

use Getopt::Std;
use Encode::Locale;
use Encode;
use Novel::Robot;

use vars qw/$writer $book $obj $chap_regex/;

#不缓冲直接输出
$| = 1;

#本地编码处理
binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

my %opt;
getopt( 'wbor', \%opt );

( $writer, $book, $obj, $chap_regex ) = @opt{ 'w', 'b', 'o', 'r' };
exit unless ( defined $obj );

my $xs = Novel::Robot->new();
$xs->set_packer('HTML');
$xs->set_parser('TXT');
$xs->{parser}{chapter_regex} = decode( locale => $chap_regex ) if($chap_regex);

my @path = split ',', $obj;

$xs->get_book({ writer => $writer, book => $book, path => \@path  });
