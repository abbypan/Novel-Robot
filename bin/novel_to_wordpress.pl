#!/usr/bin/perl 
=pod

=encoding utf8

=head1  DESC

下载小说，导入wordpress空间

=head1 EXAMPLE

    novel_to_wordpress.pl -b "http://www.dddbbb.net/html/18451/index.html" -c 言情 -w http://xxx.xxx.com  -u xxx -p xxx
    novel_to_wordpress.pl -b "http://www.jjwxc.net/onebook.php?novelid=2456" -c 原创 -w http://xxx.xxx.com  -u xxx -p xxx

=head1 USAGE

novel_to_wordpress.pl -b [index_url] -c [categories] -t [tags] -i [chapter_ids] -w [wordpress_url] -u [username] -p [password] 

=head1 OPTIONS

-b : book url，小说目录页，例如 http://www.jjwxc.net/onebook.php?novelid=2456

-c : categories，小说类别，例如 原创

-t : tags，标签，例如 顾漫

-i : chapter ids，章节序号，例如 1,4-7,10

-w : wordpress 地址

-u : wordpress 用户

-p : wordpress 密码

-h : help 帮助

=cut

use strict;
use warnings;
use utf8;

use WordPress::XMLRPC;
use Getopt::Std;
use Encode::Locale;
use Encode;




use Novel::Robot;

$| = 1;

my %opt;
getopt( 'bctiwuph', \%opt );

print_usage() if(exists $opt{h});

init_book_agent(\%opt);
post_book_to_wordpress(\%opt);

sub init_book_agent {
    my ($o) = @_;

    $o->{book_agent} = Novel::Robot->new();
    $o->{wp_agent} = init_wordpress_agent($o);

    $o->{tags}       = exists $o->{t} ? [ split ',', decode(locale =>$o->{t}) ] : [];
    $o->{categories} = exists $o->{c} ? [ split ',', decode(locale => $o->{c}) ] : [];
    $o->{chapters}   = exists $o->{i}
    ? [
        map {
        my ( $s, $e ) = split '-';
        $e ||= $s;
        ( $s .. $e )
        } ( split ',', $o->{i} )
    ]
    : [];
    return $o;
}

sub init_wordpress_agent {
    my ($o)  = @_;
    
    $o->{w}=~s#/$##;
    
    my $wp = WordPress::XMLRPC->new(
        {   username => $o->{u},
            password => $o->{p},
            proxy    => "$o->{w}/xmlrpc.php",
        }
    );
    return $wp;
}

sub post_chapter_to_wordpress {
    my ( $o, $u, $i ) = @_;

    my $c = $o->{book_agent}->get_chapter_ref($u, $i);

    my $d = {
        'title' => qq[$c->{writer} 《$c->{book}》 $i : $c->{chapter}],
        'description' => qq[<p>来自：<a href="$u">$u</a></p><p></p>$c->{content}],
        'mt_keywords' => [ $c->{writer}, $c->{book} ],
    };

    push @{ $d->{mt_keywords} }, @{ $o->{tags} } if ( @{ $o->{tags} } );
    push @{ $d->{categories} }, @{ $o->{categories} } if ( @{ $o->{categories} } );


    $d->{$_} = encode('utf8', $d->{$_}) for(qw/title description/);
    for my $k (qw/mt_keywords categories/){
        $_ = encode('utf8', $_) for @{$d->{$k}};
    }

    my $pid = $o->{wp_agent}->newPost( $d, 1 );
    my $post_url = "$o->{w}/?p=$pid";

    return $post_url;
}

sub post_book_to_wordpress {
    my ($o) = @_;

    print "\rget book to wordpress : $o->{b}";
    my $index_ref = $o->{book_agent}->get_index_ref($o->{b});
    return unless($index_ref);

    for my $i (1 .. $index_ref->{chapter_num}){
        my $u = $index_ref->{chapter_urls}[$i];
        next unless($u);
        print "\rget book to wordpress : chapter $i/$index_ref->{chapter_num} : $u";
        my $post_url = post_chapter_to_wordpress($o, $u, $i);
        print "\rpost chapter to wordpress : chapter $i/$index_ref->{chapter_num} : $post_url";
    }
    print "\n";
}

sub print_usage {
    print <<"USAGE";
[USAGE]

$0 -b "http://www.jjwxc.net/onebook.php?novelid=2456" -c 原创 -w "http://www.xxx.com" -u xxx -p xxx

[OPTION]
-b : book url，小说目录页，例如 http://www.jjwxc.net/onebook.php?novelid=2456
-c : categories，小说类别，例如 原创
-t : tags，标签，例如 顾漫
-i : chapter ids，章节序号，例如 1,4-7,10
-w : wordpress 地址
-u : wordpress 用户
-p : wordpress 密码
-h : help 帮助
USAGE
    exit;
}
