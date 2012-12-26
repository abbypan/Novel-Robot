#!/usr/bin/perl 
=pod

=encoding utf8

=head1  DESC

下载小说，存成html

=head1 EXAMPLE

    novel_to_html.pl "http://www.jjwxc.net/onebook.php?novelid=2456"

    novel_to_html.pl "http://www.dddbbb.net/html/18451/index.html"

=head1 USAGE

novel_to_html.pl [index_url]

=cut

use strict;
use warnings;
use utf8;

use HTML::TreeBuilder;
use HTML::FormatText;



use Novel::Robot;

use Encode::Locale;
use Encode;


$|=1;

my ($index_url) = @ARGV;

my $xs = Novel::Robot->new();
print "\rget book to html : $index_url";
my $index_ref = $xs->get_index_ref($index_url);
exit unless($index_ref);

my $filename = encode( locale  => "$index_ref->{writer}-$index_ref->{book}.html");
open my $fh, '>:utf8', $filename;

my $css = get_css();
my $toc = generate_toc($index_ref);
my $title = "$index_ref->{writer} 《$index_ref->{book}》";
print $fh <<__HTML__;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<title> $title </title>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style type="text/css">
$css
</style>
</head>
<body>
<div id="title"><a href="$index_url"> $title </a></div>
<div id="toc"><ol>
$toc
</ol></div>
<div id="content">
__HTML__

for my $i (1 .. $index_ref->{chapter_num}){
    my $u = $index_ref->{chapter_urls}[$i];
    next unless($u);

    print "\rget book to html : chapter $i/$index_ref->{chapter_num} : $u";
    my $chap_ref = $xs->get_chapter_ref($u, $i);

    my $j = sprintf ( "%03d# ", $i );
    my $floor = <<__FLOOR__;
<div class="floor">
<div class="fltitle">$j<a name="toc$i">$chap_ref->{chapter}</a></div>
<div class="flcontent">$chap_ref->{content}</div>
</div>
__FLOOR__
    print $fh $floor,"\n";
}
print $fh "</div></body></html>";
close $fh;
print "\n";

sub get_css
{
    my $css = <<__CSS__;
body {
	font-size: large;
	font-family: Verdana, Arial, Helvetica, sans-serif;
	margin: 1em 8em 1em 8em;
	text-indent: 2em;
	line-height: 145%;
}
#title, .fltitle {
	border-bottom: 0.2em solid #ee9b73;
	margin: 0.8em 0.2em 0.8em 0.2em;
	text-indent: 0em;
	font-size: x-large;
    font-weight: bold;
    padding-bottom: 0.25em;
}
#title, ol { line-height: 150%; }
#title { text-align: center; }
__CSS__
    return $css;
} ## end sub read_css

sub generate_toc {
    my ($r) = @_;
    my $toc='';
for my $i (1 .. $index_ref->{chapter_num}){
    my $u = $index_ref->{chapter_urls}[$i];
    next unless($u);
    $toc.=qq`<li><a href="#toc$i">$r->{chapter_info}[$i-1]{title}</a></li>\n`;
    }
    return $toc;
}
