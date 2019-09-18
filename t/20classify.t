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

dies_ok { $classify->is_voice('./samples/data1.png'), 'data' }
         'need to load params';

undef $classify;

lives_ok { $classify = TransmissionIdentifier->new( { load_params => 1 } ) }
         'load params';

ok($classify->is_voice('./samples/data1.png') ==  0, 'should be data');

ok($classify->is_voice('/cart/data/wav/2018_racing/imsa/469.155_1533496465.wav') ==  1, 'should be voice');
ok($classify->is_voice('/cart/data/training/test/data/464.325_1560721394.wav.png') ==  0, 'should be data');

done_testing();

1;
