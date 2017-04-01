# ABSTRACT: download novel /bbs thread
package Novel::Robot;
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Term::Menus;
use Parallel::ForkManager;

use Novel::Robot::Parser;
use Novel::Robot::Packer;

our $VERSION = 0.37;

sub new {
    my ( $self, %opt ) = @_;
    $opt{max_process_num} ||= 3;
    $opt{type}            ||= 'html';

    my $parser  = Novel::Robot::Parser->new(%opt);
    my $packer  = Novel::Robot::Packer->new(%opt);
    my $browser = $parser->{browser};
    bless { %opt, parser => $parser, packer => $packer, browser => $browser },
      __PACKAGE__;
}

sub set_parser {
    my ( $self, $site ) = @_;
    $self->{site} = $self->{parser}->detect_site($site);
    $self->{parser}  = Novel::Robot::Parser->new(%$self);
    return $self;
} ## end sub set_parser

sub set_packer {
    my ( $self, $type ) = @_;
    $self->{type} = $type;
    $self->{packer}  = Novel::Robot::Packer->new(%$self);
    return $self;
} ## end sub set_packer

sub get_item {
    my ( $self, $index_url, %o ) = @_;

    my $item_ref = $self->{parser}->get_item_ref( $index_url, %o );
    return unless ($item_ref);

    $self->{packer}->format_item_output( $item_ref, \%o );
    my $r = $self->{packer}->main( $item_ref, %o );
    return wantarray ? ( $r, $item_ref ) : $r;
} ## end sub get_item

sub select_item {
    my ( $self, $banner, $item_list ) = @_;

    my %item = map {
        my $class = $_->{series} || $_->{writer} || $_->{board} || '';
        my $name  = $_->{book}   || $_->{title}  || $_->{topic} || '';
        my $n     = "$class --- $name";

        $n => $_->{url};
    } @$item_list;

    my %menu = (
        Select => 'Many',
        Banner => $banner || 'Select List',
        Item_1 => {
            Text   => "]Convey[",
            Convey => [ sort keys %item ],
        },
    );

    my @select_items = &Menu( \%menu );
    my @select_results =
      map {
        my ( $class, $name ) = /^(.*) --- (.*)$/;
        { class => $class, name => $name, url => $item{$_} };
      } @select_items;

    return \@select_results;
} ## end sub select_item


1;
