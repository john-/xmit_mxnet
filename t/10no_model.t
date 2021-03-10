#!/usr/bin/perl

use strict;
use warnings;

#use Test::More tests => 6;
use Test::More;
use Test::Exception;
use Test::Files;
$| = 1;

use TransmissionIdentifier;

dies_ok { my $classify = TransmissionIdentifier->new( { load_params => 1, params => '/tmp/foo' } ) }
         'params file does not exist';

lives_ok { my $classify = TransmissionIdentifier->new( { labels => '/tmp/foo' } ) }
         'label file does not exist but ignore it';

my $classify = TransmissionIdentifier->new();

ok( defined($classify) && ref $classify eq 'TransmissionIdentifier',     'new() works' );

is($classify->hybridize, 0, 'default hybridize');
is($classify->load_params, 0, 'default load_params');
is($classify->params, 'xmit.params', 'default params file');
is($classify->labels, 'labels.txt', 'default label file');
is($classify->labels, 'labels.txt', 'default label file');
like( $classify->net, qr/\Q(9): Dense(3 -> 0, linear)\E/, 'returns network');
is($classify->batch_size, 1, 'default batch_size');
is($classify->epochs, 20, 'default epochs');
is($classify->lr, 0.001, 'default lr');
is($classify->momentum, 0.9, 'default momentum');
is($classify->log_intrvl, 0, 'default log_intrvl');

my $info;
lives_ok{ $info = $classify->info } 'got the info';

#dies_ok { $classify->is_voice('./samples/data1.png'), 'data' }
#         'need to load params';

#undef $classify;

#lives_ok { $classify = TransmissionIdentifier->new( { load_params => 1 } ) }
#         'load params';

#ok($classify->is_voice('./samples/data1.png') ==  0, 'should be data');

#ok($classify->is_voice('/cart/data/wav/2018_racing/imsa/469.155_1533496465.wav') ==  1, 'should be voice');
#ok($classify->is_voice('/cart/data/training/test/data/464.325_1560721394.wav.png') ==  0, 'should be data');

done_testing();

1;
