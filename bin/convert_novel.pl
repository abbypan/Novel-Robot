#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use Encode qw/:all/;
use Encode::Locale;
use Getopt::Std;
$|=1;
#binmode(STDIN, ":encoding(console_out)");
#binmode(STDOUT, ":encoding(console_out)");
#binmode(STDERR, ":encoding(console_out)");

my %opt;
getopt( 'ftwbsdhup', \%opt );

my $convert_file = convert_novel(%opt);

send_novel($convert_file, %opt) if($opt{d});

sub convert_novel {
    my ($f, %opt) = @_;
    $opt{t} ||= 'mobi';

    my $dst_file = $opt{f};
    $dst_file=~s/[a-z0-9]+$/$opt{t}/i;

    my ($writer,$book) = $opt{f}=~/([^\\\/]+?)-(.+?)\.[^.]+$/;
    my %conv = (
        'authors'=> $opt{w} || $writer , 
        'title'=> $opt{b} || $book , 
        'chapter-mark'=>"none" , 
        'page-breaks-before'=>"/" , 
        'max-toc-links'=>0, 
    );

    my $conv_str = join(" ", map { qq[--$_ "$conv{$_}"] } keys(%conv) );
    my $cmd=qq[ebook-convert "$opt{f}" "$dst_file" $conv_str]; 
    system($cmd);
    return $dst_file;
}

sub send_novel {
    my ($f, %opt) = @_;

    my $cmd =qq[sendEmail -u '' -m 'novel' -f $opt{s} -t $opt{d} -a $f -vv];

    $cmd.= qq[ -s $opt{h} -xu $opt{u} -xp $opt{p}] if($opt{h});

    system($cmd);
}
