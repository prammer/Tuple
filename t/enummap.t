
use warnings FATAL => 'all';
use strict;

use Test::Most;
use Tuple::Tests;
Tuple::Tests::test_isa('EnumMap');
Tuple::Tests::test_does('EnumMap');
done_testing();

