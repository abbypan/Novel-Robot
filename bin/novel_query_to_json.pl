#!/usr/bin/perl 
=pod

=encoding utf8

=head1 DESCRIPTION

查询小说，返回的信息以JSON格式输出

=head1 EXAMPLE

    novel_query_to_json.pl Jjwxc 作者 顾漫

    novel_query_to_json.pl Dddbbb 作品 拼图 


=head1 USAGE

novel_query_to_json.pl [site] [query_type] [keyword]

site: 例如 Jjwxc / Dddbbb

query_type: 例如 作品 / 作者

keyword : 查询的关键字

=cut

use strict;
use warnings;
use utf8;
use JSON;
use Encode::Locale;
use Encode;

use Novel::Robot;

my ($site,$keyword,$value) = @ARGV;
$keyword = decode( locale => $keyword);
$value = decode( locale => $value);


my $xs = Novel::Robot->new();
$xs->set_site($site);
my $query_ref = $xs->get_query_ref($keyword, $value);
exit unless($query_ref);

my $query_json = encode_json $query_ref;
print $query_json;
