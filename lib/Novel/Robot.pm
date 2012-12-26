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
    
    #批量处理小说(支持to txt/html/wordpress ...)

    novel_to_any.pl -w "http://www.jjwxc.net/oneauthor.php?authorid=3243" -m 1 -t "novel_to_html.pl {url}"

    novel_to_any.pl -s Jjwxc -o "作品 何以笙箫默" -m 1 -t "novel_to_html.pl {url}"
    

=head1 FUNCTION

    my $xs = Novel::Robot->new();
    

    #目录页

    my $index_url = 'http://www.jjwxc.net/onebook.php?novelid=2456';

    my $index_ref = $xs->get_index_ref($index_url);

    #目录页

    $xs->set_site('Jjwxc');

    my $index_ref = $xs->get_index_ref(2456);


    #章节页

    my $chapter_url = 'http://www.jjwxc.net/onebook.php?novelid=2456&chapterid=2';

    my $chapter_ref = $xs->get_chapter_ref($chapter_url, 2);

    #章节页

    $xs->set_site('Jjwxc');

    my $chapter_ref = $xs->get_chapter_ref(2456,2);


    #作者页

    my $writer_url = 'http://www.jjwxc.net/oneauthor.php?authorid=3243';

    my $writer_ref = $xs->get_writer_ref($writer_url);


    #查询

    $xs->set_site('Jjwxc');

    my $query_ref = $xs->get_query_ref($query_type, $query_value);

=cut

package Novel::Robot;
use strict;
use warnings;
use utf8;

use Encode;
use Moo;

use Novel::Robot::Browser;
use Novel::Robot::Parser;

has browser => (
    is      => 'rw',
    default => sub {
        my ($self) = @_;
        my $browser = new Novel::Robot::Browser();
        return $browser;
    },
);

has site => (
    is      => 'rw',
    default => sub {''},
);

has parser => (
    is      => 'rw',
    default => sub {
        my ($self) = @_;
        my $parser_base = new Novel::Robot::Parser();
        my $parser = $parser_base->init_parser('Base');
        return $parser;
    },
);

sub set_site {
    my ( $self, $site ) = @_;
    $self->{site} = $site if ($site);
    unless($self->{parser_list}{ $self->{site} }){
        my $parser_base = new Novel::Robot::Parser();
        $self->{parser_list}{ $self->{site} }
        = $parser_base->init_parser($self->{site});
    }
    $self->{parser} = $self->{parser_list}{ $self->{site} };
} ## end sub set_site

sub set_site_by_url {
    my ( $self, $url ) = @_;

    my $site = $self->{parser}->detect_site_by_url($url);
    
    $self->set_site($site) if ( !$self->{site} or $self->{site} ne $site );
} ## end sub set_site_by_url

sub get_index_ref {

    my ( $self, @args ) = @_;

    $self->set_site_by_url( $args[0] ) if ( $args[0] =~ m#^http://# );

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

    $self->set_site_by_url( $args[0] ) if ( $args[0] =~ m#^http://# );

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

    $self->set_site_by_url( $args[0] ) if ( $args[0] =~ m#^http://# );
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

### }}}

no Moo;
1;
