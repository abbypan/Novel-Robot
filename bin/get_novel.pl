#!/usr/bin/perl 
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Std;
use Novel::Robot;
use POSIX qw/ceil/;

$| = 1;
binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

my %opt;
getopt( 'sqkmbfrtiCSoTcRAFNPIMnUpvuB', \%opt );

my %opt_out = read_option(%opt);

my $xs = Novel::Robot->new( type => $opt_out{type}, site => $opt_out{site} );

my $info;
my $items_ref;

if($opt{f}){
    my @path = split ',', $opt{f};
    $xs->get_item(\@path, %opt_out);
}elsif($opt{b}){ #writer
    ($info, $items_ref) = $xs->{parser}->get_board_ref($opt{b}, %opt_out);
}elsif($opt{q}){ #query
    ($info, $items_ref) = $xs->{parser}->get_query_ref($opt_out{query_keyword}, %opt_out);
}elsif($opt{n}){
    get_novel_split($xs, $opt{u}, %opt_out);
}elsif($opt{u}){
    $xs->get_item($opt{u}, %opt_out);
}

if($items_ref){
    my $select = $opt{m} ? $xs->select_item($info, $items_ref) : $items_ref;
    for my $r (@$select) {
        my $u = $r->{url};
        print "\rselect : $u\n";
        $xs->get_item($u, %opt_out);
    } ## end for my $r (@$select)
}

sub read_option {
    my ( %opt )=@_;

    $opt{s} = 'txt' if($opt{f});

    my %opt_out=(
        book => $opt{u} ? decode(locale =>$opt{u}) :undef,
        category => $opt{c} ? [ split ',', decode( locale => $opt{c} ) ] : undef, 
        chapter_regex => $opt{r} ? decode( locale => $opt{r} ) : undef, 
        max_floor_num => $opt{F}, 
        max_process_num => $opt{p} // 3, 
        min_word_num => $opt{N}, 
        only_poster => $opt{A}, 
        output => $opt{o}, 
        query_keyword => $opt{k} ? decode( locale => $opt{k}) : undef, 
        query_type => $opt{q} ? decode( locale => $opt{q}) : undef, 
        remark => $opt{R} ? decode( locale => $opt{R} ) : undef, 
        select_menu => $opt{m}, 
        verbose => $opt{v} // 1, 
        site => $opt{s} || $opt{u} || $opt{b} ,
        tag => $opt{T} ? [ split ',', decode( locale => $opt{T} ) ] : undef,
        type => $opt{t} || 'html', 
        with_toc => $opt{C} // 1, 
        writer => $opt{w} ? decode(locale => $opt{w}) : undef, 
        packer_url => $opt{S}, 
        usr => $opt{U}, 
        passwd => $opt{P}, 
        chapter_ids => $opt{i} ? $xs->split_id_list($opt{i}) : undef, 
        step_chapter_num => $opt{n}, 
        board => $opt{B}, 
    );

    if($opt{i}){
        @opt_out{qw/min_chapter_num max_chapter_num/} = split '-', $opt{i};
    }

    my ($class, $item) = $opt{b} ? qw/board item/ : qw/query item/ ;
    if($opt{I}){
        ($opt_out{"min_${class}_page"}, $opt_out{"max_${class}_page"}) =
        split '-', $opt{I};
    }
    if($opt{M}){
        $opt_out{"max_${class}_${item}_num"} = $opt{M};
    }

    return %opt_out;
}

sub get_novel_split {
    my ($self, $index_url, %opt) = @_;

    my ($m, $n)=(1, undef);
    my $info = $self->{parser}->get_index_ref($index_url);
    my $num = $info->{chapter_num};
    my $en = ceil(log($num+1)/log(10));

    for(my $m = 1; $m<=$num; $m+=$opt{step_chapter_num}){
        my $n = $m+$opt{step_chapter_num}-1;
        $n = $num if($n>$num);

        my @info_list = ($info->{writer}, $info->{book}, $n)
        my $out = sprintf("%s-%s-%0${en}d.%s", 
            @info_list
            , $self->{packer}->suffix());

        $self->get_item($index_url, 
            %opt, 
            min_chapter_num => $m, 
            max_chapter_num => $n, 
            output => encode(locale=>$out), 
            title => sprintf("%s 《%s》 %0${en}d", @info_list),
        );
    }
}
