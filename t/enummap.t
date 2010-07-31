
use warnings FATAL => 'all';
use strict;

use Test::Most;
use EnumMap::Tests;
use Tuple::Tests;
EnumMap::Tests::test_does('EnumMap');
Tuple::Tests::test_identity('EnumMap');
done_testing();

