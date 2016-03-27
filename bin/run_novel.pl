#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use File::Temp qw/tempfile /;
use Encode;
use Encode::Locale;
use File::Copy;
use Getopt::Std;
use Novel::Robot;
use POSIX qw/ceil/;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

my %opt;
getopt( 'utTGCSoh', \%opt );
$opt{T} ||= 'mobi' unless(exists $opt{o});
for(qw/G C S o/){
    $opt{$_} = exists $opt{$_} ? decode(locale=>$opt{$_}) : '';
}

main_ebook(%opt);

sub main_ebook {
    my (%o) = @_;
    
    my ( $fh, $f ) = tempfile( "run_novel-html-XXXXXXXXXXXXXX", TMPDIR => 1, SUFFIX => ".html" );
    get_novel_html($o{u}, $f, $o{G});

    my ($writer, $book) = parse_writer_book($o{u}, $fh, $o{G});
    my $ebook_f = $o{o} || "$writer-$book.$o{T}";
    my ($type) = $ebook_f=~/\.([^.]+)$/;

    #conv html to ebook
    my ( $fh_e, $f_e ) = $o{t} ? tempfile( "run_novel-ebook-XXXXXXXXXXXXXXXX", 
        TMPDIR => 1, 
        SUFFIX => ".$type" ) : ('', $ebook_f);
    my $conv_cmd = encode(locale => qq[conv_novel.pl -f "$f" -t "$f_e" -w "$writer" -b "$book" $o{C}]);
    print encode(locale=>"conv to ebook $f_e\n");
    if($type ne 'html'){
    `$conv_cmd`;
    unlink($f);
}else{
    rename($f, $f_e);
}

    return unless($o{t});

    print "send ebook : $o{u}, $f_e, $o{t}\n";
    #my $cmd = qq[send_novel.pl -t $o{t} -a $f_e -m "$writer 《$book》" $o{S}];
    my $cmd = qq[sendEmail -u "$writer 《$book》" -m "$writer 《$book》" -a "$f_e" -t "$o{t}" $o{S}];
    if($o{h}){
        system(qq[ansible $o{h} -m copy -a 'src=$f_e dest=/tmp/']);
        system(encode(locale=>qq[ansible $o{h} -m shell -a '$cmd']));
        system(qq[ansible $o{h} -m shell -a 'rm $f_e']);
    }else{
        $cmd = encode(locale=>$cmd);
        `$cmd`;
    }
    unlink($f_e);
}

sub get_novel_html {
    my ($url, $f, $arg) = @_;

    my $cmd;
    if(-f $url and $url=~/\.html/i){
        copy($url, $f);
    }elsif(-f $url and $url=~/\.raw/i){
        print "convert raw\n";
        $cmd=qq[get_novel.pl -u "$url" -o "$f" -s raw -t html];
    }elsif(-f $url){
        print "convert txt\n";
        my $u = decode(locale => $url);
        my ($w, $b) = $u=~/([^\\\/]+?)-([^\\\/]+)\.txt/i;
        $cmd=qq[get_novel.pl -f "$u" -w "$w" -b "$b" -o '$f' -t html -s txt];
    }else{
        print "download $url\n";
        $cmd = qq[get_novel.pl -u "$url" -o "$f"];
        $cmd.= " $arg" if($arg);
    }

    if($cmd){
        $cmd=encode(locale=>$cmd);
        `$cmd`;
    }
}

sub parse_writer_book {
    my ($url, $fh, $arg) = @_;
    my $writer;
    my $book;

    if(-f $url and $url=~/\.html/i){
        my $u = decode(locale => $url);
        ($writer, $book) = $u=~/([^\\\/]+?)-([^\\\/]+)\.html/i;
    }else{
        my $title='';
        while(<$fh>){
            ($title) = m#<title>(.+?)</title>#;
            last if($title);
        }
        $title=decode("utf8", $title);
        ($writer, $book) = $title=~m# (.+?) 《 (.+?) 》#s;
    }

    $book.=" $arg" if($arg);
    $book=~s/[\\\/ <>\(\)\[\]]//sig;
    return ($writer, $book); 
}
