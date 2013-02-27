#!/usr/bin/perl 
=pod

=encoding utf8

=head1  DESC

下载小说，存成txt

=head1 EXAMPLE

    novel_to_txt.pl "http://www.jjwxc.net/onebook.php?novelid=2456"

    novel_to_txt.pl "http://www.dddbbb.net/html/18451/index.html"

=head1 USAGE

novel_to_txt.pl [index_url]

=cut

use strict;
use warnings;
use utf8;

use Novel::Robot::Packer;
use Novel::Robot;
use Encode::Locale;
use Encode;

$|=1;

my ($index_url) = @ARGV;

my $xs = Novel::Robot->new();
my $packer = Novel::Robot::Packer->new();
$packer->set_packer('TXT',  leftmargin => 0, rightmargin => 50 );

print "\rget book to txt : $index_url";
my $index_ref = $xs->get_index_ref($index_url);
exit unless($index_ref);

my $filename = encode( locale  => "$index_ref->{writer}-$index_ref->{book}.txt");
open my $fh, '>:utf8', $filename;

my $format_index = $packer->format_index($index_ref);
print $fh $format_index, "\n";

for my $i (1 .. $index_ref->{chapter_num}){
    my $u = $index_ref->{chapter_urls}[$i];
    next unless($u);
    print "\rget book to txt : chapter $i/$index_ref->{chapter_num} : $u";

    my $chap_ref = $xs->get_chapter_ref($u, $i);
    $chap_ref->{id} = $i;

    my $format_text = $packer->format_chapter($chap_ref);
    print $fh $format_text,"\n\n";
}
close $fh;
print "\n";
