#!/usr/bin/perl 
use strict;
use warnings;
use utf8;

use Getopt::Std;
use Encode::Locale;
use Encode;

use Novel::Robot;

$| = 1;

my %opt;
getopt( 'bctwupi', \%opt );

my $xs = Novel::Robot->new();

my $index_url = $opt{b};
$xs->set_parser($index_url);

my %packer_opt = (
    'base_url' => $opt{w},
    'usr'      => $opt{u},
    'passwd'   => $opt{p},
);
$packer_opt{tag}      = [ split ',', decode( locale => $opt{t} ) ] if ( $opt{t} );
$packer_opt{category} = [ split ',' , decode( locale => $opt{c} ) ] if ( $opt{c} );
$packer_opt{chapter_ids} = $xs->split_id_list($opt{i}) if ( $opt{i} );

$xs->set_packer( 'WordPress' );
$xs->get_book($index_url, \%packer_opt);
