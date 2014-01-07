#!/usr/bin/perl 
#  ABSTRACT: 下载小说
use strict;
use warnings;
use utf8;

use Novel::Robot;

$|=1;

my ($index_url, $type) = @ARGV;
$type ||='TXT';

my $xs = Novel::Robot->new();
$xs->set_parser($index_url);
$xs->set_packer($type);
$xs->get_book($index_url);
