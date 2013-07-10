# ABSTRACT:  小说下载器

=pod

=encoding utf8

=head1 DESCRIPTION 

=head2 支持小说输入形式

见 Novel::Robot::Parser

=head2 支持小说输出形式

见 Novel::Robot::Packer

=head1 SYNOPSIS

=head2 下载小说，存成txt/html

    novel_to_txt.pl "http://www.dddbbb.net/html/18451/index.html"

=head2 下载小说，存成html

    novel_to_html.pl "http://www.jjwxc.net/onebook.php?novelid=2456"

=head2 下载小说，导入wordpress空间

    novel_to_wordpress.pl -b "http://www.jjwxc.net/onebook.php?novelid=2456" -c 原创 -w http://xxx.xxx.com  -u xxx -p xxx

=head2 批量处理小说(支持to TXT/HTML/...)

    novel_to_any.pl -w "http://www.jjwxc.net/oneauthor.php?authorid=3243" -m 1 -t HTML

    novel_to_any.pl -s Jjwxc -q 作品 -v 何以笙箫默 -m 1 -t HTML

=head2 解析TXT，转换为HTML

    dzs_to_html.pl -w 顾漫 -b 何以笙箫默 -o hy1.txt

=head2 解析TXT，导入wordpress空间

    dzs_to_wordpress.pl -W 顾漫 -b 何以笙箫默 -o hy.txt -c 言情 -w http://xxx.xxx.com  -u xxx -p xxx

=head1 FUNCTION

=head2 new 初始化

    my $xs = Novel::Robot->new();

=head2 set_parser 设置解析引擎

    $xs->set_parser('Jjwxc');

=head2 set_packer 设置打包引擎

    $xs->set_packer('HTML');

=head2 get_book 下载整本小说

    $xs->set_parser('Jjwxc');

    my $index_url = 'http://www.jjwxc.net/onebook.php?novelid=2456';

    $xs->get_book($index_url);


    $xs->set_parser('TXT');

    $xs->get_book({ writer => '顾漫', book => '何以笙箫默', 
            path => [ '/somepath/somefile.txt' ] });

=head2 select_book 在Term下选择小说

    my $select_ref = $xs->select_book($writer_ref);

    my $select_ref = $xs->select_book($query_ref);

=cut

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

our $VERSION = 0.23;

has parser => ( is => 'rw', );
has packer => ( is => 'rw', );
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

    my $parser = $self->{parser};
    my $index_ref = $parser->get_index_ref($index_url);
    return unless ($index_ref);

    my $pk = $self->{packer};
    my ( $w_sub, $w_dst ) = $pk->open_packer( $index_ref, $o );

    $pk->write_packer( $w_sub, $pk->format_before_index($index_ref) );
    $pk->write_packer( $w_sub, $pk->format_index($index_ref) );
    $pk->write_packer( $w_sub, $pk->format_before_chapter($index_ref) );

    my $chap_ids = $self->{parser}->get_chapter_ids($index_ref, $o);

    my ($add_chap_sub, $work_chap_sub, $del_chap_sub)  = $self->get_chapter_iter($chap_ids);
    my $process_chap_sub = sub {
            my ($chap) = @_;
            $add_chap_sub->($chap);

            while ( my $chap_r = $work_chap_sub->() ) {

                $pk->write_packer( $w_sub, $pk->format_chapter($chap_r) )
                unless($parser->is_empty_chapter($chap_r));
                
                $del_chap_sub->();
            } 
        };

    my $pm = Parallel::ForkManager->new( $self->{max_process_num} );
    $pm->run_on_finish( sub {
            my ( $pid, $exit_code, $ident, $exit, $core, $chap ) = @_;
            $process_chap_sub->($chap);
        });

    for my $i (@$chap_ids) {
        my $chap_r = $parser->get_nth_chapter_info($index_ref, $i);
        my $is_empty_chapter = $parser->is_empty_chapter($chap_r);

        if($is_empty_chapter){
            my $pid = $pm->start and next;
            my $r = $parser->get_chapter_ref( $chap_r->{url}, $chap_r->{id} );
            $pm->finish( 0, $r );
        }else{
            $process_chap_sub->($chap_r);
        }

    } ## end for my $i ( 1 .. $index_ref...)

    $pm->wait_all_children;

    $pk->write_packer( $w_sub, $pk->format_after_chapter($index_ref) );

    return $w_dst;
} ## end sub get_book

sub get_chapter_iter {
    my ( $self, $chap_ids) = @_;
    return unless ($chap_ids);

    my %chap_window;
    my $work_index = 0;
    my $work_num = scalar(@$chap_ids);

    my $add_chap_sub = sub {
        my ($chap) = @_;
        $chap_window{ $chap->{id} } = $chap;
    };

    my $work_chap_sub = sub {
        return unless($work_index<$work_num);

        my $i = $chap_ids->[$work_index];
        return unless ( exists $chap_window{$i} );

        return $chap_window{$i};
    };

    my $del_chap_sub = sub {
        my $i = $chap_ids->[$work_index];
        $chap_window{$i} = undef;
        $work_index++;
    };

    return ( $add_chap_sub, $work_chap_sub, $del_chap_sub);
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
