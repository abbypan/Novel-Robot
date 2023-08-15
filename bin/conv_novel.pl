#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use Encode qw/:all/;
use Encode::Locale;
use Getopt::Long qw(:config no_ignore_case);

$| = 1;

#binmode( STDIN,  ":encoding(console_out)" );
#binmode( STDOUT, ":encoding(console_out)" );
#binmode( STDERR, ":encoding(console_out)" );

my %opt;

GetOptions(
  \%opt,
  'ebook_input|f=s',
  'ebook_output|o=s',
  'ebook_type|t=s',
  'writer|w=s', 'book|b=s',
);

my $convert_file = convert_novel( %opt );

sub convert_novel {
  my ( %opt ) = @_;

  return $opt{ebook_input} unless ( -f $opt{ebook_input} and -s $opt{ebook_input} );
  my ( $src_f_type ) = $opt{ebook_input} =~ m#\.([^.]+)$#;

  if ( !defined $opt{ebook_output} ) {
    $opt{ebook_output} = $opt{ebook_input};
    $opt{ebook_output} =~ s/\.([^.]+)$/.$opt{ebook_type}/;
  }

  ( $opt{ebook_type} ) = $opt{ebook_output} =~ m#\.([^.]+)$#;

  return $opt{ebook_input} if ( $opt{ebook_output} eq $opt{ebook_input} );

  print "conv_novel: $opt{ebook_input} => $opt{ebook_output}\n";

  if ( lc( $src_f_type ) eq lc( $opt{ebook_type} ) ) {
    copy( $opt{ebook_input}, $opt{ebook_output} );
  } else {

    my ( $writer, $book ) = $opt{ebook_input} =~ /([^\\\/]+?)-([^\\\/]+?)\.[^.\\\/]+$/;

    #$writer = encode( locale => $opt{writer} ) if ( defined $opt{writer} );
    $writer = $opt{writer} if ( defined $opt{writer} );
    $writer //= '';

    #$book = encode( locale => $opt{book} ) if ( defined $opt{book} );
    $book = $opt{book} if ( defined $opt{book} );
    $book //= '';

    my %conv = (
      'authors'            => $writer,
      'author-sort'        => $writer,
      'title'              => $book,
      'chapter-mark'       => "none",
      'page-breaks-before' => "/",
      'max-toc-links'      => 0,
    );

    my $conv_str = join( " ", map { qq[--$_ "$conv{$_}"] } keys( %conv ) );
    if ( $opt{ebook_type} =~ /\.epub$/ ) {
      $conv_str .= " --dont-split-on-page-breaks ";
    } elsif ( $opt{ebook_type} =~ /\.mobi$/ ) {
      $conv_str .= " --mobi-keep-original-images ";
    }

    my $cmd = qq[ebook-convert "$opt{ebook_input}" "$opt{ebook_output}" $conv_str];

    #system( $cmd);
    `$cmd`;

  } ## end else [ if ( lc( $src_f_type )...)]

  return $opt{ebook_output};
} ## end sub convert_novel

