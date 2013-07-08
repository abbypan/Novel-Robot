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


=head2 get_index_ref 获取目录页信息

    $xs->set_parser('Jjwxc');

    my $index_ref = $xs->get_index_ref($index_url);

=head2 get_chapter_ref 获取章节页信息

    my $chapter_url = 'http://www.jjwxc.net/onebook.php?novelid=2456&chapterid=2';

    my $chapter_ref = $xs->get_chapter_ref($chapter_url, 2);

=head2 get_writer_ref 获取作者页信息

    my $writer_url = 'http://www.jjwxc.net/oneauthor.php?authorid=3243';

    my $writer_ref = $xs->get_writer_ref($writer_url);

=head2 get_query_ref 获取查询结果

    my $query_type = '作者';

    my $query_value = '顾漫';

    my $query_ref = $xs->get_query_ref($query_type, $query_value);

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

use Novel::Robot::Browser;
use Novel::Robot::Parser;
use Novel::Robot::Packer;

our $VERSION = 0.22;

has browser => (
    is      => 'rw',
    default => sub {
        my ($self) = @_;
        my $browser = new Novel::Robot::Browser();
        return $browser;
    },
);

has parser_base => (
    is      => 'ro',
    default => sub {
        my ($self) = @_;
        my $parser_base = new Novel::Robot::Parser();
        return $parser_base;
    },
);

has parser => ( is => 'rw', );

has packer_base => (
    is      => 'ro',
    default => sub {
        my ($self) = @_;
        my $packer_base = new Novel::Robot::Packer();
        return $packer_base;
    },
);

has packer => ( is => 'rw', );

has max_process_num => ( is => 'rw', default => sub { 3 } );

sub set_parser {
    my ( $self, @parser_args ) = @_;

    $self->{parser} = $self->{parser_base}->init_parser(@parser_args);

} ## end sub set_parser

sub set_packer {
    my ( $self, @packer_args ) = @_;

    $self->{packer} = $self->{packer_base}->init_packer(@packer_args);

} ## end sub set_packer

sub get_book {
    my ( $self, $index_url , $o) = @_;
    $o ||= {};

    my $index_ref = $self->get_index_ref($index_url);
    return unless ($index_ref);

    my $pk = $self->{packer};

    my ($w_sub, $w_dst) = $pk->open_packer($index_ref, $o);

    $pk->write_packer($w_sub, $pk->format_before_index( $index_ref ));
    $pk->write_packer($w_sub, $pk->format_index( $index_ref ));

    $pk->write_packer($w_sub, $pk->format_before_chapter( $index_ref ));

    my $i = 1;
    my %temp_chap;

    my $chap_num = scalar(@{ $index_ref->{chapter_info} });

    my $pm = Parallel::ForkManager->new( $self->{max_process_num} );
    $pm->run_on_finish(
        sub {
            my ( $pid, $exit_code, $ident, $exit, $core, $r ) = @_;

            $temp_chap{ $r->{id} } = $r;

            while (1) {
                last unless ( exists $temp_chap{$i} );
                print "\rall $chap_num, now $i";
                my $chap_ref = $temp_chap{$i};
                eval {
                $pk->write_packer($w_sub, $pk->format_chapter( $chap_ref ))
                if ( $chap_ref->{content} );
                };
                $temp_chap{$i} = undef;
                $i++;
            }

        }
    );

    for my $r ( @{ $index_ref->{chapter_info} } ) {
        my $pid = $pm->start and next;

        my $chap_ref =
        ( exists $r->{content} )
        ? $r
        : $self->get_chapter_ref( $r->{url}, $r->{id} );

        $pm->finish( 0, $chap_ref );
    } ## end for my $i ( 1 .. $index_ref...)

    $pm->wait_all_children;

    $pk->write_packer($w_sub, $pk->format_after_chapter( $index_ref ));

    print "\r";

    return $w_dst;
} ## end sub get_book

sub get_book_with_single_proc {
    my ( $self, $index_url ) = @_;

    my $index_ref = $self->get_index_ref($index_url);
    return unless ($index_ref);

    my $fh = $self->{packer}->open_packer($index_ref);

    $self->{packer}->format_before_index( $fh, $index_ref );
    $self->{packer}->format_index( $fh, $index_ref );

    $self->{packer}->format_before_chapter( $fh, $index_ref );
    my $i = 0;
    for my $r ( @{ $index_ref->{chapter_info} } ) {
        $i++;
        my $chap_ref =
        ( exists $r->{content} )
        ? $r
        : $self->get_chapter_ref( $r->{url}, $r->{id} || $i );

        next unless ( $chap_ref->{content} );

        $self->{packer}->format_chapter( $fh, $chap_ref, $i );
    } ## end for my $i ( 1 .. $index_ref...)
    $self->{packer}->format_after_chapter( $fh, $index_ref );

    $self->{packer}->close_packer( $fh, $index_ref );
} ## end sub get_book

sub get_index_ref {

    my ( $self, $index_url ) = @_;

    return $self->{parser}->parse_index($index_url)
    unless ( $index_url =~ /^http/ );

    my $html_ref = $self->{browser}->request_url($index_url);

    my $ref = $self->{parser}->parse_index($html_ref);
    return unless ( defined $ref );

    $ref->{index_url} = $index_url;
    $ref->{site}      = $self->{parser}{site};

    if ( exists $ref->{more_book_info} ) {
        $self->{parser}
        ->format_abs_url( $ref->{more_book_info}, $ref->{index_url} );
        for my $r ( @{ $ref->{more_book_info} } ) {
            my $info = $self->{browser}->request_url( $r->{url} );
            next unless ( defined $info );
            $r->{function}->( $ref, $info );
        }
    }

    $self->{parser}->calc_index_chapter_num($ref);
    $self->{parser}->format_abs_url( $ref->{chapter_info}, $ref->{index_url} );

    return $ref;
} ## end sub get_index_ref

sub get_chapter_ref {
    my ( $self, $chap_url, $chap_id ) = @_;

    my $html_ref = $self->{browser}->request_url($chap_url);
    my $ref      = $self->{parser}->parse_chapter($html_ref);

    my $null_chapter_ref = {
        content => '',
        title   => '[空]',
        id      => $chap_id || 1,
    };
    return $null_chapter_ref unless ($ref);

    $ref->{content} =~ s#\s*([^><]+)(<br />\s*){1,}#<p>$1</p>\n#g;
    $ref->{content} =~ s#(\S+)$#<p>$1</p>#s;
    $ref->{content} =~ s###g;

    $ref->{url} = $chap_url;
    $ref->{id}  = $chap_id;

    return $ref;
} ## end sub get_chapter_ref

sub get_writer_ref {
    my ( $self, $writer_url ) = @_;

    my $html_ref = $self->{browser}->request_url($writer_url);

    my $writer_books = $self->{parser}->parse_writer($html_ref);
    $self->{parser}->format_abs_url( $writer_books->{booklist}, $writer_url );

    return $writer_books;
} ## end sub get_writer_ref

sub get_query_ref {
    my ( $self, $type, $keyword ) = @_;

    my ( $url, $post_vars ) =
    $self->{parser}->make_query_request( $type, $keyword );
    $url = encode( $self->{parser}->charset, $url );
    $post_vars->{$_} = encode( $self->{parser}->charset, $post_vars->{$_} )
    for keys(%$post_vars);

    my $html_ref = $self->{browser}->request_url( $url, $post_vars );
    return unless $html_ref;

    my $result = $self->{parser}->parse_query($html_ref);

    my $result_urls_ref = $self->{parser}->parse_query_result_urls($html_ref);
    for my $url (@$result_urls_ref) {
        my $h = $self->{browser}->request_url($url);
        my $r = $self->{parser}->parse_query($h);
        push @$result, @$r;
    }

    $self->{parser}->format_abs_url( $result, $url );

    return $result;
} ## end sub get_query_ref

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

no Moo;
1;
