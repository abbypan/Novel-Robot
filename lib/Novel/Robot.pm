# ABSTRACT:  小说下载器

=pod

=encoding utf8

=head1 NAME

Novel::Robot

=head1 DESCRIPTION 

小说下载器

=head2 支持站点

=item * 

Jjwxc  : 绿晋江     http://www.jjwxc.net

=item *

Dddbbb : 豆豆小说网 http://www.dddbbb.net

=back

=over

=head1 SYNOPSIS

    #下载小说，存成txt/html

    novel_to_txt.pl "http://www.dddbbb.net/html/18451/index.html"


    #下载小说，存成html

    novel_to_html.pl "http://www.jjwxc.net/onebook.php?novelid=2456"


    #下载小说，导入wordpress空间

    novel_to_wordpress.pl -b "http://www.jjwxc.net/onebook.php?novelid=2456" -c 原创 -w http://xxx.xxx.com  -u xxx -p xxx
    
    #批量处理小说(支持to TXT/HTML/...)

    novel_to_any.pl -w "http://www.jjwxc.net/oneauthor.php?authorid=3243" -m 1 -t HTML

    novel_to_any.pl -s Jjwxc -q 作品 -v 何以笙箫默 -m 1 -t HTML

    #解析TXT，转换为HTML

    dzs_to_html.pl -w 顾漫 -b 何以笙箫默 -o hy1.txt

    #解析TXT，导入wordpress空间

    dzs_to_wordpress.pl -W 顾漫 -b 何以笙箫默 -o hy.txt -c 言情 -w http://xxx.xxx.com  -u xxx -p xxx
    

=head1 FUNCTION

    #初始化

    my $xs = Novel::Robot->new();

    $xs->set_parser('Jjwxc');

    $xs->set_packer('TXT');


    #下载整本小说

    my $index_url = 'http://www.jjwxc.net/onebook.php?novelid=2456';

    $xs->get_book($index_url);


    #目录页

    my $index_ref = $xs->get_index_ref($index_url);

    my $index_ref = $xs->get_index_ref(2456);


    #章节页

    my $chapter_url = 'http://www.jjwxc.net/onebook.php?novelid=2456&chapterid=2';

    my $chapter_ref = $xs->get_chapter_ref($chapter_url, 2);

    my $chapter_ref = $xs->get_chapter_ref(2456,2);


    #作者页

    my $writer_url = 'http://www.jjwxc.net/oneauthor.php?authorid=3243';

    my $writer_ref = $xs->get_writer_ref($writer_url);


    #查询

    my $query_type = '作者';

    my $query_value = '顾漫';

    my $query_ref = $xs->get_query_ref($query_type, $query_value);

=cut

package Novel::Robot;
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Term::Menus;
use Moo;

use Novel::Robot::Browser;
use Novel::Robot::Parser;
use Novel::Robot::Packer;

our $VERSION = 0.19;

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

sub set_parser {
    my ( $self, $s, $o ) = @_;

    $self->{parser} = $self->{parser_base}->init_parser( $s, $o );

} ## end sub set_parser

sub set_packer {
    my ( $self, $p, $o ) = @_;

    $self->{packer} = $self->{packer_base}->init_packer( $p, $o );

} ## end sub set_packer

sub get_book {
    my ( $self, $index_url, $o ) = @_;
    $o ||= {};

    #print "\rget book : $index_url\n";

    my $index_ref = $self->get_index_ref($index_url);
    return unless ($index_ref);

    $self->{packer}->open_packer($index_ref);

    $self->{packer}->format_before_index($index_ref);
    $self->{packer}->format_index($index_ref);
    $self->{packer}->format_after_index($index_ref);

    $self->{packer}->format_before_chapter($index_ref);
    for my $i ( 1 .. $index_ref->{chapter_num} ) {
        #my $u = $index_ref->{chapter_urls}[$i];
        my $u = $index_ref->{chapter_info}[$i]{url};
        next unless ($u);

        #print "\rget chapter $i/$index_ref->{chapter_num} : $u";
        my $chap_ref = $self->get_chapter_ref( $u, $i );
        $self->{packer}->format_chapter( $chap_ref, $i );
    } ## end for my $i ( 1 .. $index_ref...)
    $self->{packer}->format_after_chapter($index_ref);

    $self->{packer}->close_packer();
} ## end sub get_book

sub get_index_ref {

    my ( $self, @args ) = @_;

    my ($index_url) = $self->{parser}->generate_index_url(@args);

    my $html_ref = $self->{browser}->get_url_ref($index_url);

    $self->{parser}->alter_index_before_parse($html_ref);
    my $ref = $self->{parser}->parse_index($html_ref);
    return unless ( defined $ref );

    $ref->{index_url} = $index_url;
    $ref->{site}      = $self->{parser}{site};

    return $ref unless ( exists $ref->{book_info_urls} );

    while ( my ( $url, $info_sub ) = each %{ $ref->{book_info_urls} } ) {
        my $info = $self->{browser}->get_url_ref($url);
        next unless ( defined $info );
        $info_sub->( $ref, $info );
    }

    return $ref;
} ## end sub get_index_ref

sub get_chapter_ref {
    my ( $self, @args ) = @_;

    my ( $chap_url, $chap_id ) = $self->{parser}->generate_chapter_url(@args);
    my $html_ref = $self->{browser}->get_url_ref($chap_url);
    return unless ($html_ref);

    $self->{parser}->alter_chapter_before_parse($html_ref);
    my $ref = $self->{parser}->parse_chapter($html_ref);
    return unless ($ref);

    $ref->{content} =~ s#\s*([^><]+)(<br />\s*){1,}#<p>$1</p>\n#g;
    $ref->{content} =~ s#(\S+)$#<p>$1</p>#s;
    $ref->{content} =~ s###g;

    $ref->{chapter_url} = $chap_url;
    $ref->{chapter_id}  = $chap_id;

    return $ref;
} ## end sub get_chapter_ref

sub get_empty_chapter_ref {
    my ( $self, $id ) = @_;

    my %data;
    $data{chapter_id} = $id;

    return \%data;
} ## end sub get_empty_chapter_ref

sub get_writer_ref {
    my ( $self, @args ) = @_;

    my ($writer_url) = $self->{parser}->generate_writer_url(@args);

    my $html_ref = $self->{browser}->get_url_ref($writer_url);

    my $writer_books = $self->{parser}->parse_writer($html_ref);

    return $writer_books;
} ## end sub get_writer_ref

sub get_query_ref {
    my ( $self, $type, $keyword ) = @_;

    my $key = encode( $self->{parser}->charset, $keyword );
    my ( $url, $post_vars ) = $self->{parser}->make_query_url( $type, $key );
    my $html_ref = $self->{browser}->get_url_ref( $url, $post_vars );
    return unless $html_ref;

    my $result          = $self->{parser}->parse_query($html_ref);
    my $result_urls_ref = $self->{parser}->get_query_result_urls($html_ref);
    return $result unless ( defined $result_urls_ref );

    for my $url (@$result_urls_ref) {
        my $h = $self->{browser}->get_url_ref($url);
        my $r = $self->{parser}->parse_query($h);
        push @$result, @$r;
    }

    return $result;
} ## end sub get_query_ref

sub select_book {
    my ($self, $info_ref) = @_;

    my %menu = ( 'Select' => 'Many', 'Banner' => 'Book List', );

    #菜单项，不搞层次了，恩
    my %select;
    my $i = 1;
    for my $r (@$info_ref) {
        my ( $info, $key, $url ) = @$r;
        my $item = "$info --- $key";
        $select{$item} = $url;
        $item = encode( locale => $item );
        $menu{"Item_$i"} = { Text => $item };
        $i++;
    } ## end for my $r (@$info_ref)

    #最后选出来的小说
    my @select_result;
    for my $item ( &Menu( \%menu ) ) {
        $item = decode( locale => $item );
        my ( $info, $key ) = ( $item =~ /^(.*) --- (.*)$/ );
        push @select_result, [ $info, $key, $select{$item} ];
    }

    return \@select_result;

} ## end sub select_book

sub deal_book {
    my ( $self, $book_src, $o ) = @_;
    $o ||= {};

    my $index_ref = $self->{parser}->parse_index($book_src);
    return unless ($index_ref);

    $self->{packer}->open_packer($index_ref);

    $self->{packer}->format_before_index($index_ref);
    $self->{packer}->format_index($index_ref);
    $self->{packer}->format_after_index($index_ref);

    $self->{packer}->format_before_chapter($index_ref);
    for my $i ( 1 .. $index_ref->{chapter_num} ) {
        my $chap_ref = $index_ref->{chapter_info}[$i];
        next unless ($chap_ref);

        $self->{packer}->format_chapter( $chap_ref, $i );
    } ## end for my $i ( 1 .. $index_ref...)
    $self->{packer}->format_after_chapter($index_ref);

    $self->{packer}->close_packer();
} ## end sub get_book

no Moo;
1;
