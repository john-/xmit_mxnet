#!/usr/bin/perl

use strict;
use warnings;

#use Test::More tests => 6;
use Test::More;
#plan skip_all => 'skip training for now';

use Test::Exception;
$| = 1;

use TransmissionIdentifier;

my $classify = TransmissionIdentifier->new();

ok( defined($classify) && ref $classify eq 'TransmissionIdentifier',     'new() works' );

unlink 'xmit.params';

ok($classify->train, 'training completes');

ok( -e 'xmit.params', 'params file created');

done_testing();

1;
