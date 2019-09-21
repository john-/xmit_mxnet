#!/usr/bin/perl

use strict;
use warnings;

#use Test::More tests => 6;
use Test::More;

if (!-e 'xmit.params') {
    plan skip_all => 'Test irrelevant without trained model';
}

use Test::Exception;
#use Test::Files;
$| = 1;

use TransmissionIdentifier;

my $classify = TransmissionIdentifier->new();

ok( defined($classify) && ref $classify eq 'TransmissionIdentifier',     'new() works' );

dies_ok { $classify->is_voice( input => './samples/data1.png' ), 'data' }
         'need to load params';

undef $classify;

lives_ok { $classify = TransmissionIdentifier->new( { load_params => 1 } ) }
         'load params';

ok($classify->is_voice( input => './samples/data1.png' ) ==  0, 'should be data');

ok($classify->is_voice( input => './samples/data1.wav' ) ==  0, 'should be data');
ok($classify->is_voice( input => './samples/voice1.wav') ==  1, 'should be voice');

done_testing();

1;
