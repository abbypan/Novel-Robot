#!/usr/bin/perl 
=pod

=encoding  utf8

=head1 DESCRIPTION

获取小说目录页信息，以JSON格式输出

=head1 EXAMPLE

    novel_index_to_json.pl "http://www.jjwxc.net/onebook.php?novelid=2456"

=head1 USAGE
    
novel_index_to_json.pl [index_url]
    
=cut

use strict;
use warnings;
use utf8;
use JSON;



use Novel::Robot;

my ($index_url) = @ARGV;

my $xs = Novel::Robot->new();
my $index_ref = $xs->get_index_ref($index_url);
exit unless($index_ref);

my $index_json = encode_json $index_ref;
print $index_json;
