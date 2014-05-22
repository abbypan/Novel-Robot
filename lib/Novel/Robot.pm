# ABSTRACT: download novel 小说下载器
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

our $VERSION = 0.31;

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
    bless $self->{parser}, "Novel::Robot::Parser::$self->{site}";
} ## end sub set_parser

sub set_packer {
    my ( $self, $type ) = @_;
    $self->{type} = $type;
    bless $self->{packer}, "Novel::Robot::Packer::$self->{type}";
} ## end sub set_packer

sub get_book {
    my ( $self, $index_url, %o ) = @_;

    my $book_ref = $self->{parser}->get_book_ref( $index_url, %o );
    return unless ($book_ref);

    $self->{packer}->format_book_output( $book_ref, \%o );
    my $r = $self->{packer}->main( $book_ref, %o );
    return wantarray ? ( $r, $book_ref ) : $r;
} ## end sub get_book

sub select_book {
    my ( $self, $info_ref ) = @_;

    my %menu = ( 'Select' => 'Many', 'Banner' => 'Book List', );

    #菜单项，不搞层次了，恩
    my %select;
    my $i = 1;
    for my $r (@$info_ref) {
        my $info = $r->{series} || $r->{writer} || '';
        my $item = "$info --- $r->{book}";
        $select{$item} = $r->{url};
        $item = encode( locale => $item );
        $menu{"Item_$i"} = { Text => $item };
        $i++;
    } ## end for my $r (@$info_ref)

    #最后选出来的小说
    my @select_result;
    for my $item ( &Menu( \%menu ) ) {
        $item = decode( locale => $item );
        my ( $info, $book ) = ( $item =~ /^(.*) --- (.*)$/ );
        push @select_result,
          { info => $info, book => $book, url => $select{$item} };
    }

    return \@select_result;

} ## end sub select_book

sub split_id_list {
    #1,3,9-11
    my ( $self, $id_list ) = @_;

    my @id_list = split ',', $id_list;

    my @chap_ids;
    for my $i (@id_list) {
        my ( $s, $e ) = split '-', $i;
        $e ||= $s;
        push @chap_ids, ( $s .. $e );
    }

    return \@chap_ids;
}

1;
