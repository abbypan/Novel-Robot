#!/usr/bin/perl
use Novel::Robot;

my ($url, $out_file) = @ARGV;

my $xs = Novel::Robot->new(site => $url, type=> 'html');

my $f = $xs->get_item($url);

if($out_file=~m#[^/]+\.html$#){
    rename($f, $out_file);
}else{
    system("conv_novel.pl -f $f -t $out_file");
    unlink($f);
}
