#!/usr/bin/perl 
=pod

=encoding utf8

=head1  ABSTRACT

获取作者专栏页信息，以JSON格式输出

=head1 EXAMPLE

    novel_writer_to_json.pl "http://www.jjwxc.net/oneauthor.php?authorid=3243"

=head1 USAGE

novel_writer_to_json.pl [writer_url]

=cut

use strict;
use warnings;
use utf8;
use JSON;



use Novel::Robot;

my ($writer_url) = @ARGV;

my $xs = Novel::Robot->new();
my $writer_ref = $xs->get_writer_ref($writer_url);
exit unless($writer_ref);

my $writer_json = encode_json $writer_ref->{series};
print $writer_json;
