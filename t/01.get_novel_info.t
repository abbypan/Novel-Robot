#!/usr/bin/perl
use lib '../lib';
use Novel::Robot;
use Test::More;
use Data::Dumper;
use Encode::Locale;
use Encode;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );
use utf8;

  #{ site            => 'default',
    #index_url       => 'http://www.zhonghuawuxia.com/book/71',
    #chapter_url     => 'http://www.zhonghuawuxia.com/chapter/2647',
    #book            => '武林',
    #writer          => '古龙',
    #chapter_title   => '风雪',
    #chapter_content => '怒雪威寒',
  #},
  my $r = { site            => 'jjwxc',
    index_url       => 'https://www.jjwxc.net/onebook.php?novelid=14838',
    chapter_url     => 'https://m.jjwxc.net/book2/14838/1',
    writer          => '牵机',
    book            => '断情逐妖记',
    chapter_title   => '序章',
    chapter_content => '大江',
  };
  #{ site            => 'bearead',
    #index_url       => 'https://wwwj.bearead.com/book.html?bid=b10097021',
    #chapter_url     => 'https://wwwj.bearead.com/chapter/b10097021/815269',
    ##chapter_url     => { url => 'https://wwwj.bearead.com/chapter/b10097021/815269', post_data => 'bid=b10097021&cid=354932' },
    #book            => '苏旷',
    #writer          => '飘灯',
    #chapter_title   => '树',
    #chapter_content => '旷',
  #},
  #{ site            => 'default',
    #index_url       => 'https://www.aliwx.com.cn/chapter?bid=7964189',
    #chapter_url     => 'https://www.aliwx.com.cn/reader?bid=7964189&cid=1197667',
    #book            => '青春期妖怪',
    #writer          => '飘灯',
    #chapter_title   => '普通',
    #chapter_content => '周小云',
  #},

  print "check: $r->{index_url}\n";
  my $xs = Novel::Robot->new( site => $r->{site});
  #my $xs = Novel::Robot::Parser->new( site => $r->{site}, 'use_chrome' => 1 );
  #print $xs->{browser}->request_url($r->{index_url});

  my $index_ref = $xs->{parser}->get_novel_info( $r->{index_url} );
  #print scalar(@{$index_ref->{item_list}}), "\n";
  #print $index_ref->{item_list}[-1]{url},"\n";
  is( $index_ref->{book} , $r->{book}     , "book" );
  is( $index_ref->{writer} ,  $r->{writer}, "writer" );

  #if ( ref( $r->{chapter_url} ) eq 'HASH' ) {
    #is( $index_ref->{chapter_list}[0]{url}, $r->{chapter_url}{url}, 'chapter_url' );
  #} else {
    #is( $index_ref->{chapter_list}[0]{url}, $r->{chapter_url}, 'chapter_url' );
  #}
  #is( $index_ref->{chapter_list}[0]{title} =~ /$r->{chapter_title}/ ? 1 : 0, 1, "chapter_title" );

  #print Dumper(@{$index_ref->{chapter_list}}[ 0 .. 3 ], "\n");

  my $html =
    ref( $r->{chapter_url} ) eq 'HASH'
    ? $xs->{browser}->request_url( $r->{chapter_url}{url}, $r->{chapter_url}{post_data} )
    : $xs->{browser}->request_url( $r->{chapter_url} );
  my $chapter_ref = $xs->{parser}->extract_elements(
    \$html,
    path => $xs->{parser}->scrape_novel_item(),
    sub  => $xs->{parser}->can( 'parse_novel_item' ),
  );
  is( $chapter_ref->{content} =~ /$r->{chapter_content}/ ? 1 : 0, 1, 'chapter_content' );
  print join( ",", $index_ref->{book}, $index_ref->{writer}, $index_ref->{item_list}[0]{title} ), "\n";

  #print $chapter_ref->{content},"\n";
  print "---------\n\n";

done_testing;

