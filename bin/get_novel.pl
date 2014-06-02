#!/usr/bin/perl 
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Std;
use Novel::Robot;

$| = 1;
binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

my %opt;
getopt( 'wsqkmbfrtiCSoTcRAFNPIM', \%opt );

my %opt_out = read_option(%opt);

my $xs = Novel::Robot->new( type => $opt_out{type}, site => $opt_out{site} );

my $info;
my $books_ref;

if($opt{f}){
    my @path = split ',', $opt{f};
    my $r = $xs->{parser}->parse_index(\@path, %opt_out);
    $xs->{packer}->main($r, %opt_out);
}elsif($opt{w}){ #writer
    ($info, $books_ref) = $xs->{parser}->get_writer_ref($opt{w}, %opt_out);
}elsif($opt{q}){ #query
    ($info, $books_ref) = $xs->{parser}->get_query_ref($opt_out{query_keyword}, %opt_out);
}elsif($opt{b}){
    $xs->get_book($opt{b}, %opt_out);
}

if($books_ref){
    my $select = $opt{m} ? $xs->select_book($info, $books_ref) : $books_ref;
    for my $r (@$select) {
        my $u = $r->{url};
        print "\rselect : $u\n";
        $xs->get_book($u, %opt_out);
    } ## end for my $r (@$select)
}

sub read_option {
    my ( %opt )=@_;

    $opt{s} = 'txt' if($opt{f});

    my %opt_out=(
        book => $opt{b} ? decode(locale =>$opt{b}) :undef,
        category => $opt{c} ? [ split ',', decode( locale => $opt{c} ) ] : undef, 
        chapter_regex => $opt{r} ? decode( locale => $opt{r} ) : undef, 
        max_floor_num => $opt{F}, 
        max_process_num => $opt{P} // 3, 
        min_word_num => $opt{N}, 
        only_poster => $opt{A}, 
        output => $opt{o}, 
        query_keyword => $opt{k} ? decode( locale => $opt{k}) : undef, 
        query_type => $opt{q} ? decode( locale => $opt{q}) : undef, 
        remark => $opt{R} ? decode( locale => $opt{R} ) : undef, 
        select_menu => $opt{m}, 
        show_progress_bar => $opt{S} // 1, 
        site => $opt{s} || $opt{b} || $opt{w} ,
        tag => $opt{T} ? [ split ',', decode( locale => $opt{T} ) ] : undef,
        type => $opt{t} || 'html', 
        with_toc => $opt{C} // 1, 
        writer => $opt{w} ? decode(locale => $opt{w}) : undef, 
    );

    if($opt{i}){
        @opt_out{qw/min_chapter_num max_chapter_num/} = split '-', $opt{i};
    }

    my ($class, $item) = $opt{w} ? qw/writer novel/ : 
                         $opt{q} ? qw/query item/ :
                         qw/board tiezi/;
    if($opt{I}){
        @opt_out{qw/min_${class}_page max_${class}_page/} = split '-', $opt{I};
    }
    if($opt{M}){
        $opt_out{"max_${class}_${item}_num"} = $opt{M};
    }

    return %opt_out;
}
