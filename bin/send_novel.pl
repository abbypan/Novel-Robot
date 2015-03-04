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
getopt( 'fsdhupm', \%opt );

send_novel(%opt) if($opt{d});


sub send_novel {
    my (%opt) = @_;

    $opt{f} = decode(locale => $opt{f});
    $opt{m} = decode(locale => $opt{m} || 'novel');

    my $cmd =qq[sendEmail -u '$opt{m}' -m '$opt{m}' -f '$opt{s}' -t '$opt{d}' -a '$opt{f}' -vv];
    $cmd.= qq[ -s '$opt{h}' -xu '$opt{u}' -xp '$opt{p}'] if($opt{h});

    $cmd=encode(locale=>$cmd);

    system($cmd);
}
