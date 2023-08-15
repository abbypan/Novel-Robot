#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Data::Dumper;
use Encode::Locale;
use Encode;
use File::Copy;
use File::Temp qw/tempfile /;
use FindBin;
use Getopt::Long qw(:config no_ignore_case);
use Novel::Robot;
use POSIX qw/ceil/;
#use Smart::Comments;

$| = 1;
#binmode( STDIN,  ":encoding(console_in)" );
#binmode( STDOUT, ":encoding(console_out)" );
#binmode( STDERR, ":encoding(console_out)" );

our $GET_NOVEL = "$FindBin::RealBin/get_novel.pl ";
our $CONV_NOVEL = "$FindBin::RealBin/conv_novel.pl ";
our $SEND_NOVEL = "$FindBin::RealBin/send_novel.pl ";

my %opt;
GetOptions(
    \%opt,
    'site|s=s', 'url|u=s', 'file|f=s', 'writer|w=s', 'book|b=s',
    'ebook_type|t=s', 'ebook_output|o=s',
    'item|i=s', 'page|j=s', 'cookie|c=s',
    'not_download|D', 'verbose|v',
    'term_progress_bar', 

    'board|B=s', 

    'use_chrome', 
    'with_toc', 'grep_content=s', 'filter_content=s', 'only_poster', 'min_content_word_num=i',
    'max_process_num=i', 
    'chapter_regex=s', 
    'content_path=s',  'writer_path=s',  'book_path=s', 'item_list_path=s',
    'content_regex=s', 'writer_regex=s', 'book_regex=s',

    # query type, keyword
    'query|q=s', 'keyword|k=s', 

    # remote ansible host
    #'remote|R=s',  

    # mail
    'mail_msg|m=s', 
    'mail_server|M=s', 
    'mail_port|p=s', 
    'mail_usr|U=s', 
    'mail_pwd|P=s', 
    'mail_from|F=s', 'mail_to|T=s', 
);

%opt = read_option(%opt);


main_ebook( %opt );

sub main_ebook {
  my ( %o ) = @_;

  my ( $fh, $f_e, $msg );

  if ( $o{file} and -f $o{file} ) {
    if ( $o{file} =~ /\.txt/i ) {
      my ( $writer, $book ) = $o{file} =~ /([^\\\/]+?)-([^\\\/]+?)\.[^.\\\/]+$/;
      $o{writer} ||= $writer;
      $o{book} ||= $book;
      $f_e = get_ebook( %o );
      $msg = "$o{writer} : $o{book}";
    } else {
      my ( $f_s ) = $o{file} =~ /\.([^.]+)$/i;
      ( $fh, $f_e ) = tempfile( "run_novel-raw-XXXXXXXXXXXXXX", TMPDIR => 1, SUFFIX => ".$f_s" );
      copy( $o{file}, $f_e );
      $msg = "$o{file} => $f_e";
    }
  } elsif($o{url}) {
    my $info_cmd = qq[$GET_NOVEL -u "$o{url}" -D 1];
    my $info = `$info_cmd`;
    chomp( $info );
    my ( $writer, $book, $url, $chap_num ) = split ',', $info;
    $o{writer} //= $writer // '';
    $o{book} //= $book // '';
    $f_e = get_ebook( %o );
    $msg = "$writer : $book ";
    $msg .= ", $o{item}" if(defined $o{item});
    $msg .= ", $chap_num" if(defined $chap_num);
  }else {
    $f_e = get_ebook( %o );
    $msg = "$o{site} : $o{writer} 《$o{book}》";
  }

  if($o{mail_to} and -f $f_e){
      $o{mail_attach} //= $f_e;
      #send_ebook(%o);
      $o{mail_msg} //= $msg;
      my $o_str = join( " ", map { qq[--$_  "$o{$_}"] } grep { /^mail_/ } keys( %o ) );
      system(qq[$SEND_NOVEL $o_str]);
      if($o{url}=~/^https?:/){
          unlink($f_e);
      }
  }

  return $f_e;
} ## end sub main_ebook

sub get_ebook {
  my ( %src_o ) = @_;

  my ( $fh, $html_f ) = tempfile( "run_novel-html-XXXXXXXXXXXXXX", TMPDIR => 1, SUFFIX => ".html" );

  my %o     = ( %src_o, output => $html_f );
  my $o_str = join( " ", map { qq[--$_  "$o{$_}"] } grep { ! /^(ebook|mail)_/ } keys( %o ) );

  system( qq[$GET_NOVEL $o_str] );

  my $min_id = '';
  my $book   = $o{book};
  if ( $o_str and ( $min_id ) = $o_str =~ m#--item\s+['"]?(\d+)-?\d*# ) {
    $book .= "-$min_id" if ( $min_id and $min_id > 1 );
  }

  $o{ebook_output} =~ s#/?$## if(defined $o{ebook_output});
  my $ebook_f =
      ( $o{ebook_output} and -d $o{ebook_output} ) ? "$o{ebook_output}/$o{writer}-$book.$o{ebook_type}"
    : $o{ebook_output}                             ? $o{ebook_output}
    :                                                "$o{writer}-$book.$o{ebook_type}";
  my ( $type ) = $ebook_f =~ /\.([^.]+)$/;

  return unless ( -f $html_f and -s $html_f );

  my ( $fh_e, $f_e ) = $o{t}
    ? tempfile(
    "$o{writer}-$book-ebook-XXXXXXXXXXXXXXXX",
    TMPDIR => 1,
    SUFFIX => ".$type"
    )
    : ( '', $ebook_f );

  if ( $type ne 'html' ) {
    my %o     = ( %src_o, ebook_output => $ebook_f, ebook_input => $html_f );
    my $o_str = join( " ", map { qq[--$_  "$o{$_}"] } grep { defined $o{$_} } (qw/ebook_input ebook_output ebook_type writer book/) );

    #system( encode( locale => qq[conv_novel.pl -f "$html_f" -T "$f_e" -w "$writer" -b "$book" $o{C}] ) );
    system( qq[$CONV_NOVEL $o_str] );

    unlink( $html_f ) if($o{url});
  } else {
    copy( $html_f, $f_e );
  }

  return $f_e;
} ## end sub get_ebook

sub read_option {
my ( %opt ) = @_;

if($opt{ebook_output}){
    ($opt{output}, $opt{ebook_type}) = $opt{ebook_output}=~m#^(.+?)\.([^.]+)$#;
}
$opt{ebook_type} ||= 'html';
$opt{type} = $opt{ebook_type} eq 'txt' ? 'txt': 'html';
$opt{output} = defined $opt{ebook_output} ? "$opt{output}.$opt{type}" : undef;

return %opt;
} ## end sub read_option
