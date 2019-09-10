#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;
use Test::Files;
$| = 1;

use TransmissionIdentifier;

my $classify = TransmissionIdentifier->new();

ok( defined($classify) && ref $classify eq 'TransmissionIdentifier',     'new() works' );

dies_ok { $classify->is_voice('training/test/data/461.205_1533495707.wav.png'), 'data' }
         'need to load params';

undef $classify;

lives_ok { $classify = TransmissionIdentifier->new( { load_params => 1 } ) }
         'load params';

ok($classify->is_voice('training/test/data/461.205_1533495707.wav.png') ==  0, 'should be data');

#dies_ok { $base->audio_to_spectrogram( {} ) } 'need parameters';

#dies_ok { $base->audio_to_spectrogram( 
#             { input => '/tmp/foo', output => '/tmp/bar', duration => 3.0 }
#	      ) } 'input file does not exist';

#my $src = './samples/data1.wav';
#my $cmp = './samples/data1.png';
#my $out = '/tmp/data1.png';
#unlink
#lives_ok { $base->audio_to_spectrogram( 
#             { input  => $src,
#               output => $out,
#                }
#	      ) } 'input file does not exist';

#compare_ok($cmp, $out,
#	   'files are the same');

1;
