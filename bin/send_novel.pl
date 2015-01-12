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
getopt( 'fsdhup', \%opt );

send_novel(%opt) if($opt{d});


sub send_novel {
    my (%opt) = @_;

    my $cmd =qq[sendEmail -u '' -m 'novel' -f '$opt{s}' -t '$opt{d}' -a '$opt{f}' -vv];

    $cmd.= qq[ -s '$opt{h}' -xu '$opt{u}' -xp '$opt{p}'] if($opt{h});

    system($cmd);
}
