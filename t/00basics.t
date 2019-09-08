#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use Test::Files;
$| = 1;

use TransmissionIdentifierBase;

my $base = TransmissionIdentifierBase->new();

ok( defined($base) && ref $base eq 'TransmissionIdentifierBase',     'new() works' );

dies_ok { $base->audio_to_spectrogram( {} ) } 'need parameters';

dies_ok { $base->audio_to_spectrogram( 
             { input => '/tmp/foo', output => '/tmp/bar', duration => 3.0 }
	      ) } 'input file does not exist';

lives_ok { $base->audio_to_spectrogram( 
             { input => './samples/data1.wav',
               output => '/tmp/data1.png',
                }
	      ) } 'input file does not exist';

compare_ok('./samples/data1.png', '/tmp/data1.png',
	   'files are the same');

1;
