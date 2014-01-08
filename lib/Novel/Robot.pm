# ABSTRACT:  小说下载器
package Novel::Robot;
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Term::Menus;
use Moo;
use Parallel::ForkManager;

use Novel::Robot::Parser;
use Novel::Robot::Packer;

our $VERSION = 0.28;

has parser          => ( is => 'rw', );
has packer          => ( is => 'rw', );
has max_process_num => ( is => 'rw', default => sub { 3 } );

sub set_parser {
    my ( $self, @parser_args ) = @_;

    my $parser_base = new Novel::Robot::Parser();
    $self->{parser} = $parser_base->init_parser(@parser_args);

} ## end sub set_parser

sub set_packer {
    my ( $self, @packer_args ) = @_;

    my $packer_base = new Novel::Robot::Packer();
    $self->{packer} = $packer_base->init_packer(@packer_args);

} ## end sub set_packer


sub get_book {
    my ( $self, $index_url, $o ) = @_;
    $o ||= {};

    my $parser    = $self->{parser};
    my $index_ref = $parser->get_index_ref($index_url);
    return unless ($index_ref);

    my $pk = $self->{packer};
    my ( $w_sub, $end_sub ) = $pk->open_packer( $index_ref, $o );

    $pk->write_packer( $w_sub, $pk->format_before_index($index_ref) );
    $pk->write_packer( $w_sub, $pk->format_index($index_ref) );
    $pk->write_packer( $w_sub, $pk->format_before_chapter($index_ref) );

    my $chap_ids = $self->{parser}->get_chapter_ids( $index_ref, $o );

    my ( $add_chap_sub, $work_chap_sub, $del_chap_sub ) =
      $self->get_chapter_iter($chap_ids);

    my $pm = Parallel::ForkManager->new( $self->{max_process_num} );
    $pm->run_on_finish(
        sub {
            my ( $pid, $exit_code, $ident, $exit, $core, $chap ) = @_;
            return unless($chap);

            $add_chap_sub->($chap);

            while ( my $chap_r = $work_chap_sub->() ) {

                $pk->write_packer( $w_sub, $pk->format_chapter($chap_r) )
                unless ( $parser->is_empty_chapter($chap_r) );

                $del_chap_sub->();
            }
        }
    );

    for my $i (@$chap_ids) {
        my $chap_r = $parser->get_nth_chapter_info( $index_ref, $i );
        my $is_empty_chapter = $parser->is_empty_chapter($chap_r);

        my $pid = $pm->start and next;

        my $r = $is_empty_chapter ? 
            $parser->get_chapter_ref( $chap_r->{url}, $chap_r->{id} )
            : $chap_r ;

        $pm->finish( 0, $r );

    } ## end for my $i ( 1 .. $index_ref...)

    $pm->wait_all_children;

    $pk->write_packer( $w_sub, $pk->format_after_chapter($index_ref) );

    return $end_sub->() if($end_sub and ref($end_sub) eq 'CODE');

    return $end_sub;
} ## end sub get_book

sub get_chapter_iter {
    my ( $self, $chap_ids ) = @_;
    return unless ($chap_ids);

    my %chap_window;
    my $work_index = 0;
    my $work_num   = scalar(@$chap_ids);

    my $add_chap_sub = sub {
        my ($chap) = @_;
        $chap_window{ $chap->{id} } = $chap;
    };

    my $work_chap_sub = sub {
        return unless ( $work_index < $work_num );

        my $i = $chap_ids->[$work_index];
        return unless ( exists $chap_window{$i} );

        return $chap_window{$i};
    };

    my $del_chap_sub = sub {
        my $i = $chap_ids->[$work_index];
        $chap_window{$i} = undef;
        $work_index++;
    };

    return ( $add_chap_sub, $work_chap_sub, $del_chap_sub );
}

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

no Moo;
1;
