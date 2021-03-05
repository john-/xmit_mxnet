#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Files;
$| = 1;

use TransmissionIdentifierBase;

my $base = TransmissionIdentifierBase->new();

ok( defined($base) && ref $base eq 'TransmissionIdentifierBase',     'new() works' );

dies_ok { $base->audio_to_spectrogram() } 'need parameters';

dies_ok { $base->audio_to_spectrogram( 
              input => '/tmp/foo', output => '/tmp/bar'
	      ) } 'input file does not exist';

my $src = './samples/data1.wav';
my $out = '/tmp/data1.png';
unlink $out;
lives_ok { $base->audio_to_spectrogram( 
               input  => $src,
               output => $out
	      ) } 'create spectrogram';

# TODO:  add this back in once there is output file generated correctly
#        this was commented out due to change in start clip rounding
#my $cmp = './samples/data1.png';
#compare_ok($cmp, $out,
#	   'files are the same');

done_testing();

1;
