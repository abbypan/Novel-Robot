#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use File::Temp qw/tempfile /;
use Encode;
use Encode::Locale;
use File::Copy;

my ($url, $type, $to_email, $arg, $email_arg) = @ARGV;
$type ||='mobi';
$email_arg ||= '';
$arg = decode(locale=>$arg) if($arg);

main_ebook($url, $type, $to_email, $arg, $email_arg);

sub main_ebook {
    my ($url, $type, $to_email, $arg, $email_arg) = @_;
    
    #make html
    my ( $fh, $f ) = tempfile( "send_ebook-XXXXXXXXXX", TMPDIR => 1, SUFFIX => ".html" );
    make_novel_html($url, $f, $arg);
    my ($writer, $book) = parse_writer_book($fh, $arg);

    #conv html to ebook
    my ( $fh_e, $f_e ) = $to_email ? tempfile( "send_ebook-XXXXXXXXXX", 
        TMPDIR => 1, 
        SUFFIX => ".$type" ) : ('', "$writer-$book.$type");
    my $conv_cmd = encode(locale => qq[conv_novel.pl -f '$f' -t '$f_e' -w '$writer' -b '$book']);
    print encode(locale=>"conv to mobi $f_e\n");
    `$conv_cmd`;

    #send ebook
    if($to_email){
        print "send ebook : $url, $type, $f_e, $to_email\n";
        `send_novel.pl -f '$f_e' -d '$to_email' -m '$writer 《 $book 》' $email_arg`;
        unlink($f_e);
    }

    unlink($f);
}

sub make_novel_html {
    my ($url, $f, $arg) = @_;

    my $cmd;
    if(-f $url and $url=~/\.html/){
        copy($url, $f);
    }elsif(-f $url){
        print "convert txt\n";
        my $u = decode(locale => $url);
        my ($w, $b) = $u=~/([^\\\/]+?)-([^\\\/]+)\.txt/i;
        $cmd=qq[get_novel.pl -f "$u" -w "$w" -b "$b" -o '$f' -t html -s txt];
    }else{
        print "download $url\n";
        $cmd = qq[get_novel.pl -u '$url' -o '$f'];
        $cmd.= " $arg" if($arg);
    }

    if($cmd){
        $cmd=encode(locale=>$cmd);
        `$cmd`;
    }

}

sub parse_writer_book {
    my ($fh, $arg) = @_;
    my $title;
    while(<$fh>){
        ($title) = m#<title>(.+?)</title>#;
        last if($title);
    }
    $title=decode("utf8", $title);
    my ($writer, $book) = $title=~m# (.+?) 《 (.+?) 》#s;
    $book.=" $arg" if($arg);
    $book=~s/[\\\/ <>\(\)\[\]]//sig;
    return ($writer, $book); 
}
